.section .rodata
filename: .asciz "armflix.dat"
read_mode: .asciz "r"
write_mode: .asciz "w"
fmt_menu_title:
        .asciz "--------------------------------------------------------------------\n               _   ___ __  __   ___ _    _____  __\n              /_\\ | _ \\  \\/  | | __| |  |_ _\\ \\/ /\n             / _ \\|   / |\\/| | | _|| |__ | | >  < \n            /_/ \\_\\_|_\\_|  |_| |_| |____|___/_/\\_\\\n                                                  \n"
fmt_menu_line:
    .asciz "--------------------------------------------------------------------\n"
fmt_menu_header:
    .asciz "  # TITOLO      GENERE             ANNO                     PREZZO\n"
fmt_menu_entry:
    .asciz "%3d %-10s %-20s %-20s %8d\n"
fmt_menu_options:
    .ascii "1: Aggiungi Film\n"
    .ascii "2: Elimina Film\n"
    .ascii "3: Filtra per Genere (Iterativamente)\n"
    .ascii "4: Filtra per Anno (Ricorsivamente)\n"
    .ascii "5: Mostra Prezzo medio\n"
    .ascii "6: Mostra Prezzo medio (double)\n"
    .ascii "7: Scambia due elementi (Id)\n"
    .ascii "8: Scambio della prima coppia di elementi adiacenti (rispetto al prezzo)\n"
    .ascii "9: Eliminazione del primo duplicato (rispetto a un attributo numerico)\n"
    .asciz "0: Esci\n"


fmt_prezzo_medio: .asciz "\nPrezzo medio: %d\n\n"
fmt_prezzo_medio_double: .asciz "\nPrezzo medio: %.2f\n\n"
fmt_fail_save_data: .asciz "\nImpossibile salvere i dati.\n\n"
fmt_fail_aggiungi_film: .asciz "\nMemoria insufficiente. Eliminare un'film, quindi riprovare.\n\n"
fmt_fail_calcola_prezzo_medio: .asciz "\nNessuna film presente.\n\n"
fmt_scan_int: .asciz "%d"
fmt_scan_str: .asciz "%127s"
fmt_prompt_menu: .asciz "? "
fmt_prompt_titolo: .asciz "Titolo: "
fmt_prompt_genere: .asciz "Genere: "
fmt_prompt_anno: .asciz "Anno: "
fmt_prompt_prezzo: .asciz "Prezzo: "
fmt_prompt_index: .asciz "# (fuori range per annullare): "
fmt_prompt_continue: .asciz  "Premi '104' per continuare "
.align 2

.data
n_film: .word 0

.equ max_film, 5

.equ size_film_titolo, 30
.equ size_film_genere, 15
.equ size_film_anno, 5
.equ size_film_prezzo, 4

.equ offset_film_titolo, 0
.equ offset_film_genere, offset_film_titolo + size_film_titolo
.equ offset_film_anno, offset_film_genere + size_film_genere
.equ offset_film_prezzo, offset_film_anno + size_film_anno
.equ film_size_aligned, 64

.bss
tmp_str: .skip 128
tmp_int: .skip 8
film: .skip film_size_aligned * max_film


.macro read_int prompt
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_int
    adr x1, tmp_int
    bl scanf

    ldr x0, tmp_int
.endm

.macro read_str prompt
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_str
    adr x1, tmp_str
    bl scanf
.endm

.macro save_to item, offset, size
    add x0, \item, \offset
    ldr x1, =tmp_str
    mov x2, \size
    bl strncpy

    add x0, \item, \offset + \size - 1
    strb wzr, [x0]
.endm


.text
.type main, %function
.global main
main:
    stp x29, x30, [sp, #-16]!

    bl load_data

    main_loop:
        bl print_menu
        read_int fmt_prompt_menu
        
        cmp x0, #0
        beq end_main_loop
        
        cmp x0, #1
        bne no_aggiungi_film
        bl aggiungi_film
        no_aggiungi_film:

        cmp x0, #2
        bne no_elimina_film
        bl elimina_film
        no_elimina_film:

        cmp x0, #5
        bne no_prezzo_medio_film
        bl calcola_prezzo_medio
        no_prezzo_medio_film:

        cmp x0, #6
        bne no_prezzo_medio_double_film
        bl calcola_prezzo_medio_double
        no_prezzo_medio_double_film:
        
        read_int fmt_prompt_continue
        cmp x0, #104
        beq main_loop     
    end_main_loop:

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
    .size main, (. - main)


.type load_data, %function
load_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-16]!
    
    adr x0, filename
    adr x1, read_mode
    bl fopen

    cmp x0, #0
    beq end_load_data

    mov x19, x0

    ldr x0, =n_film
    mov x1, #4
    mov x2, #1
    mov x3, x19
    bl fread

    ldr x0, =film
    mov x1, film_size_aligned
    mov x2, max_film
    mov x3, x19
    bl fread

    mov x0, x19
    bl fclose

    end_load_data:

    ldr x19, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size load_data, (. - load_data)


.type save_data, %function
save_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-16]!
    
    adr x0, filename
    adr x1, write_mode
    bl fopen

    cmp x0, #0
    beq fail_save_data

        mov x19, x0

        ldr x0, =n_film
        mov x1, #4
        mov x2, #1
        mov x3, x19
        bl fwrite

        ldr x0, =film
        mov x1, film_size_aligned
        mov x2, max_film
        mov x3, x19
        bl fwrite

        mov x0, x19
        bl fclose

        b end_save_data

    fail_save_data:
        adr x0, fmt_fail_save_data
        bl printf

    end_save_data:

    ldr x19, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size save_data, (. - save_data)


.type print_menu, %function
print_menu:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    adr x0, fmt_menu_title
    bl printf

    adr x0, fmt_menu_line
    bl printf
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf

    mov x19, #0
    ldr x20, n_film
    ldr x21, =film
    print_entries_loop:
        cmp x19, x20
        bge end_print_entries_loop

        adr x0, fmt_menu_entry
        add x1, x19, #1
        add x2, x21, offset_film_titolo
        add x3, x21, offset_film_genere
        add x4, x21, offset_film_anno
        ldr x5, [x21, offset_film_prezzo]
        bl printf

        add x19, x19, #1
        add x21, x21, film_size_aligned
        b print_entries_loop
    end_print_entries_loop:

    adr x0, fmt_menu_line
    bl printf

    adr x0, fmt_menu_options
    bl printf

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size print_menu, (. - print_menu)


.type aggiungi_film, %function
aggiungi_film:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    ldr x19, n_film
    ldr x20, =film
    mov x0, film_size_aligned
    mul x0, x19, x0
    add x20, x20, x0
    
    cmp x19, max_film
    bge fail_aggiungi_film
        read_str fmt_prompt_titolo
        save_to x20, offset_film_titolo, size_film_titolo

        read_str fmt_prompt_genere
        save_to x20, offset_film_genere, size_film_genere
        
        read_str fmt_prompt_anno
        save_to x20, offset_film_anno, size_film_anno

        read_int fmt_prompt_prezzo
        str w0, [x20, offset_film_prezzo]      

        add x19, x19, #1
        ldr x20, =n_film
        str x19, [x20]

        bl save_data

        b end_aggiungi_film
    fail_aggiungi_film:
        adr x0, fmt_fail_aggiungi_film
        bl printf
    end_aggiungi_film:
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size aggiungi_film, (. - aggiungi_film)


.type elimina_film, %function
elimina_film:
    stp x29, x30, [sp, #-16]!
    
    read_int fmt_prompt_index

    cmp x0, 1
    blt end_elimina_film

    ldr x1, n_film
    cmp x0, x1
    bgt end_elimina_film

    sub x5, x0, 1   // selected index
    ldr x6, n_film
    sub x6, x6, x0  // number of auto after selected index
    mov x7, film_size_aligned
    ldr x0, =film
    mul x1, x5, x7  // offset to dest
    add x0, x0, x1  // dest
    add x1, x0, x7  // source
    mul x2, x6, x7  // bytes to copy
    bl memcpy

    ldr x0, =n_film
    ldr x1, [x0]
    sub x1, x1, #1
    str x1, [x0]

    bl save_data

    end_elimina_film:
    
    ldp x29, x30, [sp], #16
    ret
    .size elimina_film, (. - elimina_film)



.type calcola_prezzo_medio, %function
calcola_prezzo_medio:
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_film
    cmp x0, #0
    beq calcola_prezzo_medio_error

        mov x1, #0
        mov x2, #0
        ldr x3, =film
        add x3, x3, offset_film_prezzo
        calcola_prezzo_medio_loop:
            ldr x4, [x3]
            add x1, x1, x4
            add x3, x3, film_size_aligned

            add x2, x2, #1
            cmp x2, x0
            blt calcola_prezzo_medio_loop
        
        udiv x1, x1, x0
        adr x0, fmt_prezzo_medio
        bl printf

        b end_calcola_prezzo_medio

    calcola_prezzo_medio_error:
        adr x0, fmt_fail_calcola_prezzo_medio
        bl printf
    
    end_calcola_prezzo_medio:
        ldp x29, x30, [sp], #16
        ret
        .size calcola_prezzo_medio, (. - calcola_prezzo_medio)


.type calcola_prezzo_medio_double, %function
calcola_prezzo_medio_double:
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_film
    cmp x0, #0
    beq calcola_prezzo_medio_double_error

        fmov d1, xzr
        mov x2, #0
        ldr x3, =film
        add x3, x3, offset_film_prezzo
        calcola_prezzo_medio_double_loop:
            ldr x4, [x3]
            ucvtf d4, x4
            fadd d1, d1, d4
            add x3, x3, film_size_aligned

            add x2, x2, #1
            cmp x2, x0
            blt calcola_prezzo_medio_double_loop
        
        ucvtf d0, x0
        fdiv d0, d1, d0
        adr x0, fmt_prezzo_medio_double
        bl printf

        b end_calcola_prezzo_medio_double

    calcola_prezzo_medio_double_error:
        adr x0, fmt_fail_calcola_prezzo_medio
        bl printf
    
    end_calcola_prezzo_medio_double:
        ldp x29, x30, [sp], #16
        ret
        .size calcola_prezzo_medio_double, (. - calcola_prezzo_medio_double)
