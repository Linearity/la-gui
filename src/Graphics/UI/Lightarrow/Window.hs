module Graphics.UI.Lightarrow.Window where

import Control.Monad.Reader
import Control.Monad.State.Strict
import Control.Monad.Writer.Strict
import Data.Bifunctor (first, second)
import Data.Lightarrow.Color
import Data.Lightarrow.SceneTransform
import Data.Lightarrow.SceneGraph
import Data.MonadicStreamFunction hiding (embed, first, second)
import FRP.BearRiver hiding (embed, first, second)
import FRP.BearRiver.Monad
import Graphics.Lightarrow.Rectangle
import Graphics.UI.Lightarrow.Common
import Linear (V3(..))
import Optics
import Simulation.Lightarrow.Task
import System.Lightarrow.Mouse
import System.Lightarrow.Sensation
import System.Lightarrow.Actuation

{-|

A window is a region of the screen that encloses a GUI.

Windows each have a bus that GUI elements connect to.  Each element adds a
signal (of type 'Any') to the bus stating whether or not the mouse cursor is
above it.  The window runs these elements alongside its own mouse-sensitive
dragging behavior, also connected to the bus.  The dragging only occurs when the
bus signal is 'False', that is, when the cursor is not above 'Any' of the
elements.

-}
window :: (Monad m, MonadTrans t, MonadFix (t m), MonadState s (t m), Monoid k) =>
            Lens' a Bool                                            -- ^ button state   
                -> Lens' a (Double, Double)                         -- ^ cursor position
                -> Lens' s (Double, Double, Double)                 -- ^ window position
                -> Lens' s (Double, Double)                         -- ^ window dimensions
                -> Task a (SceneGraph Double b) (t m) c             -- ^ drag mode
                -> Task a (SceneGraph Double b) (t m) ()            -- ^ idle mode
                -> BusTask Any a (k, SceneGraph Double b) m e       -- ^ window elements
                -> Task a (k, SceneGraph Double b) (t m) (d, e)     -- ^ the window 
window _button _cursor _x _d dragged idle items
            = newBus
                (busMixM    (mapTask (>>> arr (first (mempty,)))
                                (toggle click dragged' released (noBus idle)))
                            items')
    where   items'          = bus (mapTask transform (runBus items))
            click           = proc a -> do
                                e       <- mouseClick _button _cursor _x _d -< a
                                inItem  <- constM (lift ask)                -< ()   -- lift into ClockInfo
                                returnA -< gate e (not (getAny inItem))
            dragged'        = chorus (do   rest (drag _cursor _x)
                                           voice (noBus dragged))
            released        = falling (return . view _button)
            transform sf    = proc (c, a) -> do
                                a'      <- arrM xfInput     -< a
                                ecbd    <- liftSF sf        -< (c, a')
                                f       <- constM xfDraw    -< ()
                                returnA -< first (second f) ecbd
            xfInput a       = do    c   <- xfCursor _x (a ^. _cursor)
                                    return (a & _cursor .~ c)
            xfDraw          = do    (x, y, z)   <- gets (view _x)
                                    return (\(k, b) -> (k, Node (Frame (translate (V3 x y (z + 1)))) [b]))

-- | An example window drawn with rectangles
rectWindow :: (MonadFix m, RectanglePlatform p, MousePlatform p, Monoid k) =>
                BusTask Any (Sensation p) (k, SceneGraph Double (Actuation p)) m e
                    -> Task     (Sensation p)
                                (k, Tree (SceneNode Double (Actuation p)))
                                (StateT (   (Double, Double, Double),
                                            (Double, Double)    ) m)
                                (d, e)
rectWindow = window _button _cursor _1 _2 drag idle
    where   _button     = lens  (mousePressed leftMouseButton)
                                (setMousePressed leftMouseButton)
            _cursor     = lens cursorPosition setCursorPosition
            drag        = always (constM (draw Red))
            idle        = always (constM (draw Blue))
            draw c      = do    (x,y,z)     <- use _1
                                d           <- use _2
                                return (Node (Frame (translate (V3 x y z)))
                                            [Node (Term (sceneRectangle c d)) []])