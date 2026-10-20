# DC Motor Speed Control Using Classical Controllers

An interactive MATLAB GUI for simulating and comparing **P, PI, PD, and PID controllers** for a DC motor. Configure motor parameters, set a reference speed and simulation duration, tune each controller's gains independently, and visualize the motor response.

## Features

- Interactive MATLAB GUI.
- P, PI, PD, and PID controller selection.
- Independent tuning of `Kp`, `Ki`, and `Kd` for each controller.
- Editable motor parameters:
  - Armature inductance (`La`)
  - Armature resistance (`Ra`)
  - Rotor inertia (`J`)
  - Viscous friction coefficient (`B`)
  - Torque constant (`Kt`)
  - Back-EMF constant (`Ke`)
- Configurable reference speed and simulation duration.
- Three response plots:
  - Armature current, `i(t)` in amperes
  - Angular position, `theta(t)` in radians
  - Angular speed, `omega(t)` in rad/s, with a reference-speed line
- Run one controller or compare all four.
- Closed-loop stability checks and GUI status messages.

## Requirements

- MATLAB R2019b or newer.
- **Control System Toolbox**, including the `tf` and `lsim` functions.

This project runs as a MATLAB `.m` file; it is not a standalone executable.

## Getting Started

1. Download the `.m` file from this repository.
2. Open MATLAB and set the Current Folder to the directory containing the file.
3. Run the function whose name matches the file name. For example, if the file is `DC_Motor_Speed_Control_GUI.m`, enter:

   ```matlab
   DC_Motor_Speed_Control_GUI
   ```

4. The GUI opens and runs an initial simulation using the default settings.

> **Note:** The primary function name should match the `.m` filename. If you rename the file, update the function name in the source code as well.

## Using the GUI

1. Review or edit the motor parameters.
2. Set the reference speed and simulation duration.
3. Select P, PI, PD, or PID from the controller dropdown.
4. Double-click a gain cell in the table to edit it. Press Enter or click another cell to commit the value.
5. Click **Run Selected Controller** to simulate the selected controller.
6. Click **Show All Controllers** to compare the four controllers.
7. Click **Reset Defaults** to restore the default parameters, gains, and P-controller selection.

The GUI displays armature current, angular position, and angular speed. The speed plot includes a horizontal line representing the reference speed.

## DC Motor Model

The GUI uses a constant-field DC motor model:

```text
Va = La * di/dt + Ra * i + Ke * omega
J  * domega/dt + B * omega = Kt * i
dtheta/dt = omega
```

The controller acts on the speed error:

```text
e(t) = reference_speed - omega(t)
```

The controller output is the armature-voltage command. The model uses unity negative feedback on speed.

### Model variables

| Symbol | Description | Unit |
|---|---|---|
| `Va` | Armature voltage | V |
| `i` | Armature current | A |
| `omega` | Angular speed | rad/s |
| `theta` | Angular position | rad |
| `La` | Armature inductance | H |
| `Ra` | Armature resistance | Ohm |
| `J` | Rotor inertia | kg m^2 |
| `B` | Viscous friction coefficient | N m s/rad |
| `Kt` | Torque constant | N m/A |
| `Ke` | Back-EMF constant | V s/rad |

## Default Parameters

The source code provides these illustrative starting values:

| Parameter | Default value | Unit |
|---|---:|---|
| Armature inductance (`La`) | 0.12 | H |
| Armature resistance (`Ra`) | 7 | Ohm |
| Rotor inertia (`J`) | 2.12e-6 | kg m^2 |
| Viscous friction (`B`) | 6.04e-6 | N m s/rad |
| Torque constant (`Kt`) | 0.0395 | N m/A |
| Back-EMF constant (`Ke`) | 0.0395 | V s/rad |
| Reference speed | 10 | rad/s |
| Simulation duration | 5 | s |

> **Important:** `Kt` and `Ke` are illustrative placeholder values in the source code. Replace them with values from the actual motor datasheet before using results for engineering decisions.

## Controller Forms

The GUI implements the following ideal controller forms:

| Controller | Transfer function |
|---|---|
| P | `C(s) = Kp` |
| PI | `C(s) = Kp + Ki/s` |
| PD | `C(s) = Kp + Kd*s` |
| PID | `C(s) = Kp + Ki/s + Kd*s` |

Only gains relevant to the selected controller are used:

- P uses `Kp`.
- PI uses `Kp` and `Ki`.
- PD uses `Kp` and `Kd`.
- PID uses `Kp`, `Ki`, and `Kd`.

The GUI checks the closed-loop poles and reports whether the simulated closed loop is stable. Unstable responses are not successful control results; reduce the gains and simulate again.

## Troubleshooting

- **Control System Toolbox error:** Confirm that the toolbox is installed and licensed.
- **Function not found:** Make sure the `.m` file is in MATLAB's Current Folder or on the MATLAB path.
- **Filename/function mismatch:** Ensure the primary function name matches the filename.
- **Unexpected response or instability:** Check motor parameters and controller gains. Start with small gains and verify motor constants against the datasheet.
- **GUI or plotting errors:** Check the MATLAB Command Window for the original error message.

## Scope and Limitations

- The motor model is linear and assumes a constant magnetic field.
- The controller uses speed feedback; angular position is plotted as an output.
- Default motor constants are illustrative and should be validated for the actual motor.
- Results depend on motor parameters, controller gains, MATLAB version, and available toolbox functionality.

## License

No license is specified in this repository yet. Add a `LICENSE` file if you intend to publish this project under a particular open-source license.
