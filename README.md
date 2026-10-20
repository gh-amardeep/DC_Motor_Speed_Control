# DC Motor Speed Control Using Classical Controllers

An interactive MATLAB GUI for simulating and comparing **P, PI, PD, and
PID controllers** for a DC motor. The interface lets users configure
motor parameters, set a reference speed and simulation duration, tune
each controller's gains independently, and visualize the motor's
response.

## Features

-   Interactive GUI built with MATLAB UI components.
-   Four classical controller options: P, PI, PD, and PID.
-   Editable, independent (K_p), (K_i), and (K_d) gains for each
    controller.
-   Configurable motor parameters:
    -   Armature inductance, (L_a)
    -   Armature resistance, (R_a)
    -   Rotor inertia, (J)
    -   Viscous friction coefficient, (B)
    -   Torque constant, (K_t)
    -   Back-EMF constant, (K_e)
-   Configurable reference speed and simulation duration.
-   Three response plots:
    -   Armature current, (i(t))
    -   Angular position, (`\theta`{=tex}(t))
    -   Angular speed, (`\omega`{=tex}(t)), including the
        reference-speed line
-   Run one selected controller or compare all four controllers.
-   Closed-loop stability checking and status messages.

## Requirements

-   MATLAB R2019b or newer.
-   **Control System Toolbox**, including the `tf` and `lsim` functions.

The project is designed to run as a MATLAB `.m` file. It is not a
standalone executable.

## Getting Started

1.  Download or clone this repository.

2.  Open MATLAB and set the Current Folder to the directory containing
    the `.m` file.

3.  Run the function matching the file's name from the MATLAB Command
    Window. For example, if the file is named
    `DC_Motor_Speed_Control_GUI.m`, run:

    ``` matlab
    DC_Motor_Speed_Control_GUI
    ```

4.  The GUI opens and runs an initial simulation using the default
    settings.

> **Important:** In MATLAB, the primary function name should match the
> `.m` filename. If you rename the file, update the primary function
> name accordingly.

## Using the GUI

1.  Review or change the motor parameters.
2.  Enter the desired reference speed and simulation duration.
3.  Select P, PI, PD, or PID from the controller dropdown.
4.  Edit the controller gains in the table. Double-click a cell to edit
    it, then press Enter or click another cell to commit the value.
5.  Click **Run Selected Controller** to simulate the selected
    controller.
6.  Click **Show All Controllers** to compare the responses of all four
    controllers.
7.  Click **Reset Defaults** to restore the default parameters, gains,
    and P-controller selection.

The GUI plots current, angular position, and angular speed. The speed
plot includes a horizontal reference-speed line.

## DC Motor Model

The GUI uses the constant-field DC motor model:

\[ V_a = L_a`\frac{di}{dt}`{=tex} + R_a i + K_e`\omega`{=tex} \]

\[ J`\frac{d\omega}{dt}`{=tex} + B`\omega `{=tex}= K_t i \]

\[ `\frac{d\theta}{dt}`{=tex} = `\omega`{=tex} \]

where:

  Symbol             Description
  ------------------ ------------------------------
  (V_a)              Armature voltage
  \(i\)              Armature current
  (`\omega`{=tex})   Angular speed
  (`\theta`{=tex})   Angular position
  (L_a)              Armature inductance
  (R_a)              Armature resistance
  \(J\)              Rotor inertia
  \(B\)              Viscous friction coefficient
  (K_t)              Torque constant
  (K_e)              Back-EMF constant

The controller acts on speed error,
(e(t)=`\omega`{=tex}\_{`\mathrm{ref}`{=tex}}-`\omega`{=tex}(t)), and its
output is the armature voltage command. The model uses unity negative
feedback on speed.

## Default Parameters

The source file provides the following illustrative starting values:

  Parameter                                              Default value
  --------------------------- ----------------------------------------
  Armature inductance (L_a)                                     0.12 H
  Armature resistance (R_a)                                        7 Ω
  Rotor inertia (J)                 (2.12`\times10`{=tex}\^{-6}) kg·m²
  Viscous friction (B)          (6.04`\times10`{=tex}\^{-6}) N·m·s/rad
  Torque constant (K_t)                                   0.0395 N·m/A
  Back-EMF constant (K_e)                               0.0395 V·s/rad
  Reference speed                                             10 rad/s
  Simulation duration                                              5 s

**Important:** The (K_t) and (K_e) values are illustrative placeholders
in the source code. Replace them with values from the actual motor
datasheet before using the results for engineering decisions.

## Controller Forms

The GUI implements these ideal controller forms:

-   **P:** (C(s)=K_p)
-   **PI:** (C(s)=K_p+`\frac{K_i}{s}`{=tex})
-   **PD:** (C(s)=K_p+K_d s)
-   **PID:** (C(s)=K_p+`\frac{K_i}{s}`{=tex}+K_d s)

Only the gains relevant to the selected controller are used. The GUI
checks closed-loop poles and reports whether the simulated closed loop
is stable. Unstable responses should not be interpreted as successful
control performance.

## Troubleshooting

-   **Control System Toolbox error:** Confirm that the toolbox is
    available and licensed.
-   **Function not found:** Ensure the `.m` file is in MATLAB's Current
    Folder or on the MATLAB path.
-   **Filename/function mismatch:** Make sure the primary function name
    matches the filename.
-   **Unexpected response or instability:** Check the motor parameters
    and controller gains. Start with small gains and verify the motor
    constants against the datasheet.
-   **Plots or GUI errors:** Check the MATLAB Command Window for the
    original error message.

## Project Scope and Limitations

-   The motor model is linear and assumes a constant magnetic field.
-   The controller is designed around speed feedback; angular position
    is plotted as an output.
-   The source uses illustrative motor constants that should be
    validated for a real motor.
-   Simulation results depend on the motor parameters, controller gains,
    MATLAB version, and available toolbox functionality.

## License

No license is specified in this repository yet. Add a `LICENSE` file if
you intend to publish the project under a particular open-source
license.
