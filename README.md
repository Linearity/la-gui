# la-gui

This package provides very basic GUI features to Lightarrow applications.

So far it is mostly just proof that GUIs can be expressed with signal function
tasks.  Still, the `Graphics.UI.Lightarrow.Modulate` module provides a
high-level function to add a window with sliders to a task, which feeds the
slider positions to it as a second input signal.

This is relatively easy to use.  For example, the following task draws a red
rectangle of varying width and height, determined by two sliders in a window:

    let     f (a, [])       = f (a, [0, 0])
            f (a, [k1])     = f (a, [k1, 0])
            f (_, k1:k2:_)  = let   w   = (k1 + 1) * 100
                                    h   = (k2 + 1) * 100
                                in Node (Term (sceneRectangle Red (w, h))) []
        in modulateWithSliders 2
            (always (constant (arr f)))