# 3d Finite Element Module

This folder contains the three-dimensional finite element implementation of the coupled Richards equation in deformable porous media.

The 3d module represents the main scientific contribution of this repository.

It is designed for:

- Full 3d hydromechanical simulations
- Large-scale nonlinear problem solving
- Performance analysis of iterative schemes
- Physical applications to swelling soils

---

## Folder Structure

### FEM3D/

This directory contains the three-dimensional finite element assembly routines:

- Element matrix construction
- Global stiffness matrix assembly
- Mass matrix assembly
- Divergence matrix

It defines the spatial discretization of the 3d domain.

---

### models3D/

This folder includes:

- Hydraulic coefficient definitions
- Van Genuchten model
- Braudeau (Vertisol) hydraulic model
- Nonlinear constitutive laws

It describes the physical properties of the deformable porous medium.

---

### solvers3D/

This directory contains the nonlinear solvers for the 3d Richards equation.

It includes:

- L-scheme implementation
- Nonlinear iteration control
- Boundary condition enforcement
- Conditioning diagnostics
- Convergence monitoring

---

### main.m

The main.m file drives the complete 3d simulation workflow using:

- Fully implicit Euler time discretization
- Nonlinear L-scheme iterations
- Spatial and temporal loops

Two categories of simulations are provided:

#### Numerical validation

- Spatial convergence studies
- Temporal convergence studies
- Robustness analysis

#### Physical simulations

- Deformable porous media
- Swelling clay (Vertisol) applications

---

### utils3D/

This directory contains post-processing and numerical analysis tools:

- Error computation
- Diagnostic utilities
- Performance evaluation

---

## How to Run

From the project root directory, use:

run_3d_model

or directly:

main

depending on the selected execution mode.


---

## Scientific Context

The model is based on a coupled formulation of the Richards equation in deformable porous media, with application to swelling soils (Vertisols).

The 3d implementation enables detailed investigation of:

- Nonlinear solver robustness
- Conditioning of the discrete system
- Computational efficiency
- Sensitivity to hydraulic models