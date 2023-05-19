.section .rodata
filename: .asciz "armflix.dat"
read_mode: .asciz "r"
write_mode: .asciz "w"
fmt_menu_title:
        .asciz "---------------------------------------------------------------------------------\n               _   ___ __  __   ___ _    _____  __\n              /_\\ | _ \\  \\/  | | __| |  |_ _\\ \\/ /\n             / _ \\|   / |\\/| | | _|| |__ | | >  < \n            /_/ \\_\\_|_\\_|  |_| |_| |____|___/_/\\_\\\n                                                  \n"
fmt_menu_line:
    .asciz "---------------------------------------------------------------------------------\n"
fmt_menu_header:
    .asciz "  # TITOLO                         GENERE             ANNO               PREZZO\n"
fmt_menu_entry:
    .asciz "%3d %-30s %-18s %-10d %10d\n"
fmt_menu_options:
    .ascii "1: Aggiungi Film\n"
    .ascii "2: Elimina Film\n"
    .ascii "3: Filtra per Genere (Iterativamente)\n"
    .ascii "4: Filtra per Anno (Ricorsivamente)\n"
    .ascii "5: Mostra Prezzo medio\n"
    .ascii "6: Scambia due elementi (Id)\n"
    .ascii "7: Scambio della prima coppia di elementi adiacenti (rispetto al prezzo)\n"
    .ascii "8: Eliminazione del primo duplicato (rispetto a un attributo numerico)\n"
    .asciz "0: Esci\n"

fmt_prezzo_medio: .asciz "\nPrezzo medio: %.2f\n\n"
fmt_fail_save_data: .asciz "\nImpossibile salvere i dati.\n\n"
fmt_fail_aggiungi_film: .asciz "\nMemoria insufficiente. Eliminare almeno un film, quindi riprovare.\n\n"
fmt_fail_calcola_prezzo_medio: .asciz "\nNessun film presente.\n\n"
fmt_continua: .asciz "\nVuoi continuare? Premi 1 per confermare oppure qualsiasi altro numero per terminare il programma\n\n"
fmt_scan_int: .asciz "%d"
fmt_scan_str: .asciz "%127s"
fmt_scan_titolo: .asciz "%[^\n]"
fmt_pulisci_buffer: .asciz "%c"
fmt_prompt_menu: .asciz "> "
fmt_prompt_titolo: .asciz "Titolo: "
fmt_prompt_genere: .asciz "Genere: "
fmt_prompt_anno: .asciz "Anno: "
fmt_prompt_prezzo: .asciz "Prezzo: "
fmt_prompt_index: .asciz "# (fuori range per annullare): "
.align 2

.data
n_film: .word 0
n_film_temp: .word 0

.equ max_film, 5

.equ size_film_titolo, 30
.equ size_film_genere, 18
.equ size_film_anno, 4
.equ size_film_prezzo, 4

.equ offset_film_titolo, 0
.equ offset_film_genere, offset_film_titolo + size_film_titolo //30
.equ offset_film_anno, offset_film_genere + size_film_genere //48
.equ offset_film_prezzo, offset_film_anno + size_film_anno //52
.equ film_size_aligned, 64

.bss
tmp_str: .skip 64
tmp_int: .skip 8
film: .skip film_size_aligned * max_film
film_temp: .skip max_film * film_size_aligned


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

.macro read_titolo 
    adr x0, fmt_prompt_titolo
    bl printf

    adr x0, fmt_pulisci_buffer
    adr x1, tmp_str
    bl scanf
    adr x0, fmt_scan_titolo
    adr x1, tmp_str
    bl scanf
.endm

    

.text
.type main, %function
.global main
main:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!

    bl load_data

    main_loop:
        ldrsw x0, n_film
        ldr x1, =film
        bl print_menu
        read_int fmt_prompt_menu
        mov x20, x0
        
        cmp x20, #0
        beq end_main_loop
        
        cmp x20, #1
        bne no_aggiungi_film
        bl aggiungi_film
        no_aggiungi_film:

        cmp x20, #2
        bne no_elimina_film
        bl elimina_film
        no_elimina_film:

        cmp x20, #3
        bne no_filtro_genere
        bl filtra_per_genere
        no_filtro_genere:

        cmp x20, #4
        bne no_filtro_ricorsivo
        bl filtro_per_anno_ricorsivo
        no_filtro_ricorsivo:

        cmp x20, #5
        bne no_prezzo_medio_film
        bl calcola_prezzo_medio
        no_prezzo_medio_film: 
               
        adr x0, fmt_continua
        bl printf 
        read_int fmt_prompt_menu
        mov x20, x0
        cmp x20, #1
        bne end_main_loop
        b main_loop
    end_main_loop:

    mov w0, #0
    ldp x20, x21, [sp], #16
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
  
    //x0 numero film da stampare
    //x1 indirizzo struttura dati in cui sono memorizzati i film
    mov x19, x0 //conserviamo i parametri per stampare i film, ci servono per la funzione print_film
    mov x20, x1

    adr x0, fmt_menu_title
    bl printf

    adr x0, fmt_menu_line
    bl printf
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf
    
    mov x0, x19 //ripristiniamo i parametri della funzione print_filmy
    mov x1, x20
    bl print_film

    adr x0, fmt_menu_line
    bl printf

    adr x0, fmt_menu_options
    bl printf

    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size print_menu, (. - print_menu)

.type print_film, %function
print_film:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    str x21, [sp, #-16]!

    //x0 numero film da stampare
    //x1 indirizzo struttura dati in cui sono memorizzati i film

    mov x19, #0
    mov x20, x0
    mov x21, x1
    print_entries_loop:
        cmp x19, x20
        bge end_print_entries_loop

        adr x0, fmt_menu_entry
        add x1, x19, #1
        add x2, x21, offset_film_titolo
        add x3, x21, offset_film_genere        
        ldr x4, [x21, offset_film_anno]        
        ldr x5, [x21, offset_film_prezzo]
        bl printf
        
        add x19, x19, #1
        add x21, x21, film_size_aligned
        b print_entries_loop
    end_print_entries_loop:


    ldr x21, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size print_film, (. - print_film)




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

        read_titolo
        //read_str fmt_prompt_titolo
        save_to x20, offset_film_titolo, size_film_titolo

        read_str fmt_prompt_genere
        save_to x20, offset_film_genere, size_film_genere
        
        read_int fmt_prompt_anno
        str w0, [x20, offset_film_anno]          
        
        read_int fmt_prompt_prezzo
        str w0, [x20, offset_film_prezzo]      

        add x19, x19, #1 //Incrementa n film
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

        fmov d1, xzr
        mov x2, #0
        ldr x3, =film
        add x3, x3, offset_film_prezzo
        calcola_prezzo_medio_loop:
            ldr x4, [x3]
            ucvtf d4, x4
            fadd d1, d1, d4
            add x3, x3, film_size_aligned

            add x2, x2, #1
            cmp x2, x0
            blt calcola_prezzo_medio_loop
        
        ucvtf d0, x0
        fdiv d0, d1, d0
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

.type filtra_per_genere, %function
filtra_per_genere:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!
  
    read_str fmt_prompt_genere
    adr x20, tmp_str //Indirizzo Input genere
    ldr x21, =film // indirizzo struttura che contiene i film 
    
    ldr w22, n_film  //w22 = numero film   
    mov x23, #0 //w23 = contatore 
    add x21, x21, offset_film_genere// indirizzo in cui c'e il genere nella struttura dati    
    filtra_per_genere_loop:     
        cmp w23,w22
        beq filtra_per_genere_loop_endloop 
        
        ldr x0, =tmp_str //ind
        mov x1,x21  //ind
        bl confronta_due_stringhe //restituisce 1 se sono uguali 

        cmp x0,#0
        beq endif
        mov x0, x23
        bl copia_film_in_posizione_in_var_temp       

       
        endif:     

        add x21, x21, film_size_aligned //incremento l'indirizzo per scandire l'elemento successivo
        add x23,x23,#1
        b filtra_per_genere_loop

    filtra_per_genere_loop_endloop:

    ldrsw x0, n_film_temp
    ldr x1, =film_temp
    bl print_menu

    mov w0, #0 //azzera n_film_temp
    ldr x1, =n_film_temp
    str w0, [x1]

    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size filtra_per_genere, (. - filtra_per_genere)

.type confronta_due_stringhe, %function
confronta_due_stringhe:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    str x22, [sp, #-16]!

    mov x5, #1 //true

    loop:
        ldrb w20, [x0]
        ldrb w21, [x1]
        cmp w20, #0 //controllo se e non e nessuno carattere
        beq endloop
        cmp w21, #0
        beq endloop
        
        cmp w20, w21
        bne diversi    

        add x0, x0, #1
        add x1, x1, #1
        b loop
    diversi:
        mov x5,#0 //metti a false
    endloop:

    mov x0,x5
    ldr x22,  [sp], #16
    ldp x20, x21, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size confronta_due_stringhe, (. - confronta_due_stringhe)

.type copia_film_in_posizione_in_var_temp, %function
copia_film_in_posizione_in_var_temp:  //copia i dati di un singolo film in una struttura dati temporanea
    stp x29, x30, [sp, #-16]!
    str x24, [sp, #-16]!
    
    //Parametri della funzione che vengono passati:
    //x0 = posizione film

    //calcolo indirizzo src della variabile film (vedi: linea 43)
    ldr x1, =film //parametro indirizzo src memcpy
    mov x2, film_size_aligned //parametro size src memcpy
    //calcolo indirizzo di sorgente quale riga andare a copiare 
    madd x1, x0, x2,x1 //x1 e' indirizzo sorgente
                //x23 posizione
    //calcolo indirizzo di destinazione di film_temp (vedi: linea 44)
    ldr x0, =film_temp   //indirizzo variabile temporanea di destinazione       
    ldrsw x24, n_film_temp //numero elementi variabile temporanea di destinazione
    madd x0, x24, x2,x0   // parametro indirizzo destinazione memcpy
    bl memcpy
    //incremento n_film_temp che indica il numero di film che contiene la variabile temporanea
    add x24,x24,#1
    ldr x1, =n_film_temp
    str x24, [x1]        


    ldr x24, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size copia_film_in_posizione_in_var_temp, (. - copia_film_in_posizione_in_var_temp)


.type filtro_per_anno_ricorsivo, %function
filtro_per_anno_ricorsivo:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!

    ldr x22, n_film
    cmp x22, #0
    beq filtro_ricorsivo_error

    read_int fmt_prompt_anno
 
    mov x1, #0
    bl filtro_ricorsivo
    b end_filtro_ricorsivo

    filtro_ricorsivo_error:
        adr x0, fmt_fail_calcola_prezzo_medio
        bl printf

    end_filtro_ricorsivo:

    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x29, x30, [sp], #16
    ret 
    .size filtro_per_anno_ricorsivo, (. - filtro_per_anno_ricorsivo)

.type filtro_ricorsivo, %function
filtro_ricorsivo:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!

    mov x20, x0 // anno
    mov x23, x1 // contato re

    ldr x22, =film // i film

    ldrsw x21, n_film // numero film
    cmp x23, x21
    blt caso_ricorsivo 

    caso_base:
        ldrsw x0, n_film_temp // numero film temporaneo
        ldr x1, =film_temp // struttura film temporanea
        bl print_menu
        b end_ricorsione

    caso_ricorsivo:
        mov x7, film_size_aligned // dimensione film
        madd x6, x23, x7, x22 // indirizzo film attuale = contatore * 64 + film
        mov x4, x6
        add x6, x6, offset_film_anno // qua ci sta l'anno all'indirizzo film attuale

        ldr w5, [x6] // valore anno
        cmp w5, w20
        bne no_copia_film

        copia_film:
            mov x0, x23
            bl copia_film_in_posizione_in_var_temp

        no_copia_film:
            mov x0, x20
            add x1, x23, #1
            bl filtro_ricorsivo


    end_ricorsione:
        mov w0, #0 //azzera n_film_temp
        ldr x1, =n_film_temp
        str w0, [x1]

    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x29, x30, [sp], #16
    ret 
    .size filtro_ricorsivo, (. - filtro_ricorsivo)
