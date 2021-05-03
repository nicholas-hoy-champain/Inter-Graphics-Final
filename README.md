# Soap Bubble Simulation
Graphics Final Project by Brandon Boras &amp; Nicholas Perell. This started off as just a visual simulation for thin film interference, and it ended up slightly ballooning into a myriad of other features and graphical settings. As it is implemented in Unity, most of the shader's options are actually available through the material that the shader is applied to.

`Uses Unity 2020.2.1f1`

## Features
 ### Thin-Film Interference
 #### Light Spectrum Sampler
 A sampler of a rainbow texture is mapped to the bubble's UV and altered based on the viewing angle to recreate how white light is refracted into different colors through the film. This can be replaced with a spectrum of a specific set of colors if a different palette is needed.
 #### Fresnel Value
 The oil becomes more transparent the closer the viewing angle is to the normal of the bubble's surface at that point. This causes it to be visible as a ring around the bubble instead of simply mapped directly over the UV.
 
 ### Reflection
 From taking the scene relative to the camera and displaying a warped and slightly grayscaled version of it mapped onto the bubble
 
 ### Pooling of oil on the bottom of a sphere due to gravity
 As oil is affected by gravity, it is actually able to slide down the bubble and concentrate in the bottom in heavier amounts, this is partially what causes the banding of colors, as the oil refracts light differently due to the thickness of each "wave" of oil.
 
 ### Basic Phong Lighting Implementation
 A bubble really doesn't look completely right without strong light reflection

## Controls
 * ***Left Mouse Button*** - When held, rotates the camera proportional to how the cursor is moved
 * ***Middle Mouse Button / Right Mouse Button*** - When held, the perspective shifts inverse to the directions the mouse is moved.
 * ***Scrolling Mouse Wheel*** - Scrolling up moves the camera forward, scrolling down moves the camera backward.
 * ***WASD Keys/Arrow Keys*** - Moves the camera left and right and forward and backward from its current perspective.
 * ***E Key*** - Raises the camera.
 * ***Q Key*** - Lowers the camera.
 * ***Left Shift Key*** - When held. increases the speed at which the keyboard keys move the camera around.
