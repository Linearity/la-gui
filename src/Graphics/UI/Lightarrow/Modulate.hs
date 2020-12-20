module Graphics.UI.Lightarrow.Modulate where

import Control.Monad.Fix
import Control.Monad.Trans
import qualified Data.Bifunctor as BF
import FRP.BearRiver
import FRP.BearRiver.Monad
import Lightarrow
import Optics

import Graphics.UI.Lightarrow.Slider
import Graphics.UI.Lightarrow.Window

-- | Feed a task's second input channel with the positions of a given number
-- of sliders displayed in a window, all drawn with rectangles.
modulateWithSliders :: (MonadFix m, RectanglePlatform p, MousePlatform p) =>
                            Double
                                -> Task     (Sensation p, [Double])
                                            (SceneGraph Double (Actuation p))
                                            m
                                            ()
                                -> Task     (Sensation p)
                                            (SceneGraph Double (Actuation p))
                                            m
                                            ()
modulateWithSliders n m
        = newBus
            (chorus
                (do     busVoice (mapTask (>>> firstOutputToBus) gui)
                        lift (mapTask (secondInputFromBus >>>) (noBus m))))
    where   gui             = mapTask runW guiWin
            runW            = execStateSF ((0, 0, 0), (50, n * 20))
            guiWin          = rectWindow (chorus (mapM_ (\k -> voice (mapTask (runS k) rectSlider)) [0..(n-1)]))
            runS k          = execStateSF (((0, ((n - 1) / 2 - k) * 20, 0), (40, 5)), 0)