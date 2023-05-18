# ArmFlix

<img src="https://i.imgur.com/hNINSrj.png" title="Logo magnifico fatto dallo strabiliante Gabriele Grillo" style="width: 500px; display: block; margin-left: auto; margin-right: auto;">

ArmFlix is a TUI (Text-based User Interface) App developed for ARM64 CPU. It is part of the final exam of the Computer Architecture course at UNICAL and aims to implement the following points:

1. - [X] Menù and interaction with it. (Works but It needs the other points. )

2. - [X] Array with multiple types of data and print.

3. - [X] Add/remove element. (fixing bugs, assigned to Giuseppuzzu )

4. - [X] File I/O ✔️

5. - [X] Filter on some type of data (iterative).

6. - [ ] Filter on some type of data (recursive).

7. - [X] Statistic with a result non integer (Average Price) ✔️

8. - [ ] Swap elements.

9. - [ ] Swap of the first pair of adjacent unordered elements with respect to a numerical attribute.

10. - [ ] Elimination of the first duplicate (intended as an element equal to the previous one) with respect to a numerical attribute.

10. - [] Elimination of the first duplicate (intended as an element equal to the previous one) with respect to a numerical attribute

## Usage
### Build the executable  
`aarch64-linux-gnu-gcc -o armflix -static progetto.s`

### Execute the program  
`qemu-aarch64 armflix`
