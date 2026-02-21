# 2d Finite Element Module

This folder contains the two-dimensional finite element implementation of the coupled Richards equation in deformable porous media.

The 2d module is primarily designed for:

- Numerical validation of the nonlinear scheme
- Convergence analysis (spatial and temporal)
- Solver performance assessment


---

## Folder Structure

### FEM2D/

This directory contains the finite element assembly routines:

- Element matrix construction  
- Global stiffness matrix assembly  
- Mass matrix assembly 
- divergence matrix

It represents the core spatial discretization layer of the 2D formulation.

---

### models2D/

This folder includes:

- Hydraulic coefficient definitions (coefficients_matrix)  
- Van Genuchten hydraulic functions  
- Braudeau (Vertisol) model implementation  
- Nonlinear constitutive relationships  

It defines the physical and hydraulic properties of the porous medium.

---

### solvers2D/

This directory contains the nonlinear solver implementations.

The function solveNonLinearLscheme implements the L-scheme iterative method
for solving the nonlinear Richards equation.

It also includes:

- Nonlinear iteration control  
- Stabilization through the L-parameter  
- boundary conditions  
- Conditioning diagnostics  
- Convergence monitoring  

---

### main.m

The main.m file performs the complete time integration using:

- Fully implicit Euler scheme  
- Nonlinear L-scheme iterations  
- Spatial and temporal loop execution  
This file also contains the function responsible for automatically creating the results/ folder

It includes two main simulation categories:

#### Numerical validation cases

- Spatial convergence  
- Temporal convergence  
- Scheme robustness analysis  

#### Physical test cases

- Deformable porous media simulations  
- Swelling clay (Vertisol) applications  

---

### utils2D/

This directory contains numerical analysis utilities:

- L2 error computation  
- Convergence rate evaluation  
- Diagnostic tools  

---

## How to Run

From the project root directory, use:

run_2d_model

or directly:

main

depending on the selected execution mode.

 
