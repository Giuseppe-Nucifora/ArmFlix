.section .rodata
filename: .asciz "armflix.dat" // NOME FILE
read_mode: .asciz "r"  // VARIABILE DI LETTURA PER I FILE
write_mode: .asciz "w"  // VARIABILE DI SCRITTURA PER I FILE
fmt_menu_title:
        .asciz "---------------------------------------------------------------------------------\n               _   ___ __  __   ___ _    _____  __\n              /_\\ | _ \\  \\/  | | __| |  |_ _\\ \\/ /\n             / _ \\|   / |\\/| | | _|| |__ | | >  < \n            /_/ \\_\\_|_\\_|  |_| |_| |____|___/_/\\_\\\n                                                  \n"
fmt_menu_line:
    .asciz "---------------------------------------------------------------------------------\n"

fmt_menu_header:
    .asciz "  # TITOLO                         GENERE             ANNO               PREZZO\n"

//FORMAT STRING CON I DATI CHE DEVE INSERIRE L'UTENTE E LE TIPOLOGIE DI DATI (d= decimale, s= stringa)
fmt_menu_entry:
    .asciz "%3d %-30s %-18s %-10d %10d\n"

//FORMAT STRING PER LE SCELTE DELLE FUNZIONI
fmt_menu_options:
    .ascii "1: Aggiungi Film\n"
    .ascii "2: Elimina Film\n"
    .ascii "3: Filtra per Genere (Iterativamente)\n"
    .ascii "4: Filtra per Anno (Ricorsivamente)\n"
    .ascii "5: Mostra Prezzo medio\n"
    .ascii "6: Scambia posizione tra due elementi\n"
    .ascii "7: Scambio della prima coppia di elementi adiacenti non ordinati rispetto al prezzo (ordine crescente)\n"
    .ascii "8: Eliminazione del primo duplicato (inteso come elemento uguale al precedente) rispetto all'anno\n"
    .asciz "0: ESCI\n"

fmt_sezione_menu: .asciz "\n--------------------------------| MENÙ |-----------------------------------------\n"
fmt_sezione_filtro_genere: .asciz "\n---------------------------| FILTRO GENERE |-------------------------------------\n"
fmt_sezione_filtro_anno: .asciz "\n----------------------------| FILTRO ANNO |--------------------------------------\n"
fmt_no_sezione: .asciz ""
fmt_prezzo_medio: .asciz "\nPrezzo medio: %.2f\n\n"
fmt_fail_save_data: .asciz "\nImpossibile salvere i dati.\n\n"
fmt_fail_aggiungi_film: .asciz "\nMemoria insufficiente. Eliminare almeno un film, quindi riprovare.\n\n"
fmt_nessun_film_presente: .asciz "\nNessun film presente.\n\n"
fmt_fail_less_film: .asciz "\nMeno di due film presenti. Impossibile effettuare l'operazione.\n\n"
fmt_continua: .asciz "\nPremi 1 per ritornare al MENÙ oppure premi qualsiasi altro numero per TERMINARE il programma.\n\n"
///FORMAT STRING PER LA LETTURE
fmt_scan_int: .asciz "%d"
fmt_scan_str: .asciz "%127s"
fmt_scan_titolo: .asciz "%[^\n]"
fmt_pulisci_buffer: .asciz "%c"
fmt_prompt_menu: .asciz "> "
fmt_spaziatura: .asciz "\n\n\n"

fmt_prompt_titolo: .asciz "Titolo: "
fmt_prompt_genere: .asciz "Genere: "
fmt_prompt_anno: .asciz "Anno: "
fmt_prompt_prezzo: .asciz "Prezzo: "
fmt_prompt_index: .asciz "Inserisci posizione film da eliminare (fuori range per annullare): "
fmt_scambio_primo_film: .asciz "Inserire posizione primo film da scambiare: "
fmt_scambio_secondo_film: .asciz "Inserire posizione secondo film da scambiare: "
fmt_scambio_effettuato: .asciz "\nElemento in posizione %d (Prezzo %d) scambiato con elemento in posizione %d (Prezzo %d).\n"
fmt_eliminazione_effettuata: .asciz "\nElemento in posizione %d (Anno %d) eliminato.\n"
fmt_nessuna_eliminazione: .asciz "\nNessun duplicato trovato.\n"
fmt_nessuno_scambio: .asciz "\nNessuno scambio effettuato. Gli elementi sono disposti in ordine crescente in base al prezzo.\n"
fmt_errore_inserisci_numero: .asciz "\nInserisci un numero.\n\n"
fmt_inserisci_un_valido: .asciz "\nInserisci un numero compreso nel range delle posizioni.\n"
fmt_numeri_uguali: .asciz "\nLe due posizioni inserite sono uguali!\n"
.align 2       // ALLINEAMENTO DELLA MEMORIA

.data
n_film: .word 0
n_film_temp: .word 0

.equ max_film, 5    //MASSIMO DI FILM CHE SI POSSONO INSERIRE

//DICHIARAZIONE DELLA DIMENZIONE DELLE SINGOLE VARIABILI
.equ size_film_titolo, 30
.equ size_film_genere, 18
.equ size_film_anno, 4
.equ size_film_prezzo, 4

//DICHIARAZIONE DEGLI OFFSET. GLI OFFSET INDICANO QUANTI BYTE DOBBIAMO AGGIUNGERE AD UN INDIRIZZO PER POTERNE OTTERENERE UNO SPECIFICO
.equ offset_film_titolo, 0
.equ offset_film_genere, offset_film_titolo + size_film_titolo //30
.equ offset_film_anno, offset_film_genere + size_film_genere //48
.equ offset_film_prezzo, offset_film_anno + size_film_anno //52
.equ film_size_aligned, 64

.bss //NELLA SEZIONE BSS VENGONO SALVATE SOLO LE DIMENSIONI DI VARIABILI O ARRAY
//64 BIT PER ACQUISIRE LE STRINGHE E 8 BIT PER ACQUISIRE GLI INTERI
tmp_str: .skip 64
tmp_int: .skip 8

//CONTIENE L'INSIEME DELLE TUPLE, OVVERO TUTTI I GIOCHI CHE ANDIAMO A SALVARE. LA SUA DIMENSIONE E' DATA DALLA DIMENSIONE DI UNA TUPLA MOLTIPLICATA PER IL NUMERO
//MASSIMO DI GIOCHI
film: .skip film_size_aligned * max_film

film_temp: .skip max_film * film_size_aligned

// MACRO PER LA LETTURA DI UN INTERO DA INPUT
.macro read_int prompt
   adr x0, \prompt
   bl scan_int
.endm
// MACRO PER LA LETTURA DI UNA STRINGA DA INPUT
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

.macro stampa_film numero_film, struttura_film, fmt_sezione
    ldrsw x0, \numero_film
    adr x1, \struttura_film
    adr x2, \fmt_sezione
    bl stampa_tutti_i_film
.endm

.macro svuota_variabile_temporanea
    mov w0, #0 //azzera n_film_temp
    ldr x1, =n_film_temp
    str w0, [x1] 
.endm
    
.macro stampa_messaggio_premi_uno_per_continuare
    adr x0, fmt_continua
    bl printf 
    read_int fmt_prompt_menu
    mov x20, x0
    cmp x20, #1
    bne end_main_loop
.endm


.text
.type main, %function
.global main
main:
    stp x29, x30, [sp, #-16]!
    str x20, [sp, #-16]!

    bl load_data    //load_data carica i dati dal file binario alla memoria

    main_loop:
        adr x0, fmt_spaziatura
        bl printf   //stampa dei caratteri new line per lasciare spazio per le stampe successive 

        stampa_film n_film, film, fmt_sezione_menu  //stampa i film e i relativi attributi uno sotto l'altro
        bl print_menu   //stampa le voci del menu

        read_int fmt_prompt_menu    //stampa il prompt e legge il numero inserito in input
        mov x20, x0        //x0 contiene il numero letto in input che corrisponde ad una voce del menù (vedi fmt_menu_options)
                           //copia il contenuto di x0 nel registro non volatile x20 in modo da non perdere il valore
        cmp x20, #0        //confronta se la voce del menù inserita è 0 = ESCI
        beq end_main_loop  // se si esce dal main_loop e finisce l'esecuzione del programma
        
        cmp x20, #1        //confronta se la voce del menù inserita è 1 = Aggiungi film
        bne no_aggiungi_film //se no salta in no_aggiungi_film per fare ulteriori confronti
        bl aggiungi_film    // se si invoca la funzione aggiungi_film 
        no_aggiungi_film:

        cmp x20, #2      //confronta se la voce del menù inserita è 2 = Elimina film
        bne no_elimina_film //se no salta in no_elimina_film per fare ulteriori confronti
        bl elimina_film     // se si invoca la funzione elimina_film
        no_elimina_film:

        cmp x20, #3     //confronta se la voce del menù inserita è 3 = Filtra Genere (Iterativo)
        bne no_filtro_genere    //se no salta in no_filtro_genere per fare ulteriori confronti
        b blocco_filtra_genere  // se si salta nel blocco_filtra_genere
        blocco_filtra_genere:   
            bl filtra_per_genere    //invoca la funzione filtra_per_genere
            stampa_messaggio_premi_uno_per_continuare   //stampa un messaggio (fmt_continua) se l'utente preme 1 va al menù altrimenti termina il programma
        no_filtro_genere:

        cmp x20, #4     //confronta se la voce del menù inserita è 4 = Filtra Anno (Ricorsivo)
        bne no_filtro_ricorsivo      //se no salta in no_filtro_ricorsivo per fare ulteriori confronti
        b blocco_filtro_ricorsivo    // se si salta nel blocco_filtro_ricorsivo
        blocco_filtro_ricorsivo:
            bl filtro_per_anno_ricorsivo    //invoca la funzione filtro_per_anno_ricorsivo
            stampa_messaggio_premi_uno_per_continuare   //stampa un messaggio (fmt_continua) se l'utente preme 1 va al menù altrimenti termina il programma
        no_filtro_ricorsivo:

        cmp x20, #5     //confronta se la voce del menù inserita è 5 = Stampa prezzo medio
        bne no_prezzo_medio_film    //se no salta in no_prezzo_medio_film per fare ulteriori confronti
        b blocco_prezzo_medio   // se si salta nel blocco_prezzo_medio
        blocco_prezzo_medio:
            bl calcola_prezzo_medio     //invoca la funzione calcola_prezzo_medio
            stampa_messaggio_premi_uno_per_continuare   //stampa un messaggio (fmt_continua) se l'utente preme 1 va al menù altrimenti termina il programma
        no_prezzo_medio_film: 

        cmp x20, #6     //confronta se la voce del menù inserita è 6 = Scambia posizione elementi
        bne no_scambio_posizione_film   //se no salta in no_scambio_posizione_film per fare ulteriori confronti
        bl scambio_posizione_film       // se si invoca la funzione scambio_posizione_film
        no_scambio_posizione_film:

        cmp x20, #7     //confronta se la voce del menù inserita è 7 = Scambio della prima coppia di elementi adiacenti non ordinati rispetto al prezzo
        bne no_scambio_prezzo   //se no salta in no_scambio_prezzo per fare ulteriori confronti
        bl scambio_prezzo       // se si invoca la funzione scambio_prezzo
        no_scambio_prezzo:

        cmp x20, #8     //confronta se la voce del menù inserita è 8 = Eliminazione del primo duplicato (inteso come elemento uguale al precedente) rispetto all'anno
        bne no_elimina_duplicato     //se no salta in no_elimina_duplicato per fare ulteriori confronti
        bl elimina_duplicato         // se si invoca la funzione elimina_duplicato
        no_elimina_duplicato:
        
        b main_loop     //salta in main_loop per ciclare
    end_main_loop:

    mov w0, #0
    ldr x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size main, (. - main)

.type scan_int, %function
scan_int:                       
//Passato in x0 l'indirizzo del prompt da visualizare, legge in input e stampa un messaggio di errore se l'input inserito non è un numero e chiede di inserire un nuovo input finche non viene inserito un numero
//Quando viene inserito un numero lo copia in x0
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-16]!

    //x0 indirizzo prompt
    mov x19, x0 //copia il contenuto di x0 in x19 (non volatile) per conservare il valore dopo eventuali chiamate a funzioni
    loop_int: 
    mov x0, x19  //ogni volta che viene eseguito viene stampato il prompt 
    bl printf

    adr x0, fmt_scan_int    //fmt_scan_int format string tipizzata ad un numero 
    adr x1, tmp_int         // variabile temporanea dove verrà salvato l'input 
    bl scanf                // funzione scanf che legge l'input
                            // scanf restituisce 0 se c'è stato un errore durante la lettura, altrimenti, restituisce un valore intero che rappresenta il numero di elementi correttamente letti e assegnati alle variabili di destinazione. 
    cmp x0, #0      // confronta il valore restituito da scanf con zero
    bne ok          // se non sono uguali è stato inserito un numero, quindi l'inserimento è andato a buon fine. Salta nel blocco ok
    adr x0, fmt_errore_inserisci_numero     // se sono uguali c'è stato un errore
    bl printf       //stampa un messaggio di errore
    adr x0, fmt_pulisci_buffer      //fa una lettura a vuoto per eliminare elementi residui nel buffer
    adr x1, tmp_int
    bl scanf
    b loop_int      //ciclia

    ok:
    ldr x0, tmp_int    //restituisce il l'input letto 
    
    ldr x19, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size scan_int, (. - scan_int)


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
print_menu:     //stampa le voci del menù (fmt_menu_options) ed eventuali stringhe di abbellimento (fmt_menu_line)
    stp x29, x30, [sp, #-16]!
        
    adr x0, fmt_menu_line
    bl printf

    adr x0, fmt_menu_options
    bl printf
    
    ldp x29, x30, [sp], #16
    ret
    .size print_menu, (. - print_menu)

.type stampa_tutti_i_film, %function
stampa_tutti_i_film:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, X22, [sp, #-16]!
  
    mov x20, x0     //x0 numero film da stampare
    mov x21, x1     //x1 indirizzo struttura dati in cui sono memorizzati i film
    mov x22, x2      //x2 indirizzo sezione da visualizzare prima dei film
    
    adr x0, fmt_menu_title
    bl printf       //stampa nome del programma
    mov x0, x22
    bl printf       //stampa la sezione attuale vedi (fmt_sezione)
    adr x0, fmt_menu_line
    bl printf       
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf
    
    mov x19, #0
    print_entries_loop:     //stampa i singoli film 
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


    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size stampa_tutti_i_film, (. - stampa_tutti_i_film)




.type aggiungi_film, %function
aggiungi_film:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    ldr x19, n_film
    ldr x20, =film //INSIEME DELLE TUPLE
    mov x0, film_size_aligned // DIMENZIONE DI UNA TUPLA
    mul x0, x19, x0
    add x20, x20, x0
    
    cmp x19, max_film //COMPARA L'INDICE CORRENTE DEL FILM CON IL MAX DI FILM CHE SI POSSONO AGGIUNGERE 
    bge fail_aggiungi_film //SALT0 ALLA STAMPA DELLA MEMORIA INSUFFICENTE
        //LETTURA E SALVATAGGIO DEL FILM 
        read_titolo
        save_to x20, offset_film_titolo, size_film_titolo

        read_str fmt_prompt_genere
        save_to x20, offset_film_genere, size_film_genere
        
        read_int fmt_prompt_anno
        str w0, [x20, offset_film_anno]          
        
        read_int fmt_prompt_prezzo
        str w0, [x20, offset_film_prezzo]      

        add x19, x19, #1 //INCREMENTO DEL CONTATORE DI 1
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
   
    ldr x1, n_film //CARICA LA PRIMA TUPLA
    cmp x1, #0 //COMPARA L'INDICE DELLA PRIMA TUPLA CON 0
    beq end_elimina_film_error // SE NON CI SONO ELEMNTI SALTA ALLA FINE DELLA FUNZIONE

    read_int fmt_prompt_index
    
    //CONTROLLA SE L'INPUT SIA PIU' PICCOLO DI 1, TERMINA PERCHE' FUORI DAL RANGE
    cmp x0, 1
    blt end_elimina_film

    //CONTROLLA SE L'INPUT SIA PIU' GRANDE DEL MASSIMO DEI FILM, TERMINA PERCHE' FUORI DAL RANGE
    ldr x1, n_film
    cmp x0, x1
    bgt end_elimina_film

    sub x5, x0, 1   //SELEZIONA L'INDICE, VIENE GESTITO CON LO 0 BASED
    ldr x6, n_film
    sub x6, x6, x0  //ELEMNTO SUCCESSIVO A QUELLO DELL'INPUT
    mov x7, film_size_aligned
    ldr x0, =film
    mul x1, x5, x7  //MOLTIPLICA L'INDICE CORRENTE CON LA DIMENZIONE DELLA TUPLA PER CALCOLANRNE LA DISTANZA  

    add x0, x0, x1  //DESTINAZIONE 
    add x1, x0, x7  //SORGENTE
    mul x2, x6, x7  //BYTE DA COPIARE
    bl memcpy

    ldr x0, =n_film
    ldr x1, [x0]
    sub x1, x1, #1
    str x1, [x0]

    bl save_data
    b end_elimina_film

    end_elimina_film_error:
        adr x0, fmt_nessun_film_presente
        bl printf

    end_elimina_film:
    
    ldp x29, x30, [sp], #16
    ret
    .size elimina_film, (. - elimina_film)


.type calcola_prezzo_medio, %function
calcola_prezzo_medio:
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_film      //Carico nel registro x0 il numero di film presenti nel file armflix.dat
    cmp x0, #0          //Confronto il numero di film con 0
    beq calcola_prezzo_medio_error       //Se il numero di film è pari a 0 faccio un branch in "calcola_prezzo_medio_error" dove stampo un messaggio di errore

        fmov d1, xzr            //Copia in d1 il valore 0
        mov x2, #0              //Contatore
        ldr x3, =film           //Carica in x3 l'indirizzo dell'etichetta film
        add x3, x3, offset_film_prezzo      //Aggiunge il numero di byte necessari per prelevare i prezzi 
        calcola_prezzo_medio_loop:
            ldr x4, [x3]        //Carico il valore di x3 in x4
            ucvtf d4, x4        //Converte il valore intero in floating point e lo carica in x4
            fadd d1, d1, d4     //Sommo i prezzi letti e li carico in d1
            add x3, x3, film_size_aligned   //Aggiunge il numero di byte necessari per prelevare il prezzo successivo

            add x2, x2, #1      //Incremento il contatore 
            cmp x2, x0           //Confronto il contatore con il numero di film
            blt calcola_prezzo_medio_loop        //Se il n° di prezzi letti è minore del n° di film, salta nel blocco "calcola_prezzo_medio_loop" per ciclare le istruzioni
        
        ucvtf d0, x0        
        fdiv d0, d1, d0      //Divido la somma dei prezzi e la divido per il numero di film
        adr x0, fmt_prezzo_medio
        bl printf           //Stampo il prezzo medio

        b end_calcola_prezzo_medio

    calcola_prezzo_medio_error:
        adr x0, fmt_nessun_film_presente
        bl printf          //stampo un messaggio di errore se non ci sono film inseriti
    
    end_calcola_prezzo_medio:
        ldp x29, x30, [sp], #16
        ret
        .size calcola_prezzo_medio, (. - calcola_prezzo_medio)

.type filtra_per_genere, %function
filtra_per_genere:
    stp x29, x30, [sp, #-16]!
    stp x20, x21, [sp, #-16]!
    stp x22, x23, [sp, #-16]!
  
    ldr w22, n_film  //Carico il numero dei film
    cmp w22, #0      //Confronto il numero dei film con 0
    beq filtro_genere_error     //se sono uguali, quindi sono ci sono film inseriti salta nel blocco filtro_genere_error

    read_str fmt_prompt_genere      //Leggi il genere da ricercare
    adr x20, tmp_str                //Carica l'indirizzo della variabile temporanea su cui è memorizzato il genere
    ldr x21, =film                  //Carica indirizzo struttura dati che contiene tutti i film     

    mov x23, #0     //copia in w23 zero. w0 registro contatore
    add x21, x21, offset_film_genere    //Somma all'indirizzo di tutti i film, l'offset in modo da ottenere l'indirizzo preciso in cui ci saranno i valori corrispondenti al genere  
    filtra_per_genere_loop:             //loop che scandisce i generi dei film e li confronta con il genere inserito
        cmp w23,w22         //confronta contatore con il numero dei film 
        beq filtra_per_genere_loop_endloop  //se sono uguali significa che ho finito di scandire la struttura e quindi salto filtra_per_genere_loop_endloop 
        
        mov x0, x20  //passo come primo parametro il genere inserito in input
        mov x1,x21   //passo come secondo parametro il genere ottenuto scandendo la struttura
        bl confronta_due_stringhe       //invoco la funzione confronta_due_stringhe che restituisce 1 se le stringhe passate come parametri sono uguali, restituisce 0 se diverse
                                        //confronta_due_stringhe fa differenza tra maiuscole e minuscole
        cmp x0,#0           //Confronta il valore restituito dalla funzione confronta_due_stringhe con 0
        beq endif           //Se uguale a zero, le stringhe sono diverse, salta nel endif per ciclare di nuovo
        mov x0, x23         //Se uguale a uno, copia in x0 il contatore che rappresenta la posizione del film su cui si è fatto il confronto del genere per passarlo come parametro alla funzione che segue
        bl copia_film_in_posizione_in_var_temp      // invoca la funzione copia_film_in_posizione_in_var_temp che data una posizione copia il film che corrisponde in quella posizione e tutti i suoi attributi nella variabile temporanea (film_temp)
        endif:     

        add x21, x21, film_size_aligned //incremento di size l'indirizzo del genere del film attuale per ottenere l'indirizzo del genere del film successivo
        add x23,x23,#1  //incremento il contatore, la posizione del film 
        b filtra_per_genere_loop        //salta in filtra_per_genere_loop per ciclare

    filtra_per_genere_loop_endloop:        //blocco fine ciclo
                                           //ora nella varibile temporanea ci sono i film filtrati
    stampa_film n_film_temp, film_temp, fmt_sezione_filtro_genere      //stampa i film che sono presenti nella variabile temporanea, quindi i film che corrispondono al genere inserito in input

    svuota_variabile_temporanea            //Una volta visualizzati i film, imposta il numero dei film della variabile temporanea a zero, in modo da poterla utilizzare per utilizzi futuri (viene utilizzata da altre funzioni)
    b end_filtro_genere     //salta nel blocco end_filtro_genere per terminare la funzione

    filtro_genere_error:
        adr x0, fmt_nessun_film_presente
        bl printf       //stampa messaggio di errore quando non ci sono film presenti 

    end_filtro_genere:

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

    mov x5, #1 //uno

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
        mov x5,#0 //metti a zero
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

    ldr x20, n_film
    cmp x20, #0
    beq filtro_ricorsivo_error

    read_int fmt_prompt_anno
 
    mov x1, #0
    bl filtro_ricorsivo
    b end_filtro_ricorsivo

    filtro_ricorsivo_error:
        adr x0, fmt_nessun_film_presente
        bl printf

    end_filtro_ricorsivo:

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
        ldr x2, =fmt_sezione_filtro_anno
        bl stampa_tutti_i_film
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
        svuota_variabile_temporanea

    ldp x22, x23, [sp], #16
    ldp x20, x21, [sp], #16
    ldp x29, x30, [sp], #16
    ret 
    .size filtro_ricorsivo, (. - filtro_ricorsivo)

.type scambio_posizione_film, %function
scambio_posizione_film:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    str x21, [sp, #-16]!

    ldrsw x21, n_film    // Carica il numero di film Signed Word 
    cmp x21, #0          // Confronta numero dei film
    beq scambio_posizione_error //se è uguale a zero (non ci sono film), salta nel blocco scambio_posizione_error

    cmp x21, #1         // Confronta numero dei film con 1 
    beq scambio_posizione_error_less //Se uguale a uno, salta nel blocco scambio_posizione_error_less
                                     //Devono essere stati inseriti almeno due film per poter fare lo scambio

    read_int fmt_scambio_primo_film         //Stampa il prompt e legge la posizione del primo film da scambiare
    mov x19, x0                             //Copia la posizione del primo film in un registro non volatile x19
	read_int fmt_scambio_secondo_film       //Stampa il prompt e legge la posizione del secondo film da scambiare
	mov x20, x0                             //Copia la posizione del secondo film in un registro non volatile x20    
                                //Le posizioni inserite devono essere comprese tra 1 e il numero dei film inseriti
    cmp x19, #1                 //Confronta la posizione del primo film con 1
    blt fuori_range_posizioni   //se è minore salta nel blocco fuori_range_posizioni

    cmp x19, x21                 //Confronta la posizione del primo film con il numero dei film inseriti
    bgt fuori_range_posizioni    //se è maggiore salta nel blocco fuori_range_posizioni

    cmp x20, #1                 //Confronta la posizione del secondo film con il numero con 1 
    blt fuori_range_posizioni   //se è minore salta nel blocco fuori_range_posizioni

    cmp x20, x21                //Confronta la posizione del secondo film con il numero dei film inseriti
    bgt fuori_range_posizioni   //se è maggiore salta nel blocco fuori_range_posizioni

    cmp x19, x20                //Confronta entrambe le posizioni inserite
    beq numeri_uguali           //se sono uguali salta nel blocco numeri_uguali 


    sub x19, x19, #1   //sottrai uno alla posizione del primo film da scambiare 
    sub x20, x20, #1   //sottrai uno alla posizione del secondo film da scambiare 
                       //si sottrae uno, perchè la funzione scambia_due_elementi_nella_struttura considera per comodità le posizioni dei film partendo da zero 
    mov x0, x19        //passo come primo parametro della funzione scambia_due_elementi_nella_struttura la posizione del primo film da scambiare
    mov x1, x20        //passo come secondo parametro della funzione scambia_due_elementi_nella_struttura la posizione del secondo film da scambiare
    bl scambia_due_elementi_nella_struttura     //invoco la funzione scambia_due_elementi_nella_struttura
                        //gli elementi sono stati scambiati! Ora gli elementi sono in memoria
    bl save_data        //invoco la funzione save_data che salva i dati in memoria nel file binario (armflix.dat)
    b end_scambio_posizione     //salta nel end_scambio_posizione che termina la funzione 

    scambio_posizione_error:    
        adr x0, fmt_nessun_film_presente
        bl printf               //stampa messaggio di errore "Nessun film presente"
        b end_scambio_posizione     //salta nel end_scambio_posizione che termina la funzione 
    
    scambio_posizione_error_less:
        adr x0, fmt_fail_less_film
        bl printf           //stampa messaggio di errore "Meno di due film film presenti"
        b end_scambio_posizione     //salta nel end_scambio_posizione che termina la funzione 

    numeri_uguali:
        adr x0, fmt_numeri_uguali
        bl printf          //stampa messaggio di errore "Le due posizioni inserite sono uguali"
        b end_scambio_posizione     //salta nel end_scambio_posizione che termina la funzione 
    
    fuori_range_posizioni:
        adr x0, fmt_inserisci_un_valido
        bl printf          //stampa messaggio di errore" Inserisci un numero compreso nel range delle posizioni."


    end_scambio_posizione:

    ldr x21, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size scambio_posizione_film, (. - scambio_posizione_film)

.type scambia_due_elementi_nella_struttura, %function
scambia_due_elementi_nella_struttura:
    stp x29, x30, [sp, #-16]!
    stp x21, x22, [sp, #-16]! 
    

    //x0 posizione del primo elemento da scambiare 
    //x1 posizione del secondo elemento da scambiare            
    mov x21, x0
    mov x22, x1

    bl copia_film_in_posizione_in_var_temp  //copia il primo elemento nella variabile temporanea

    ldr x4, =film
    mov x2, film_size_aligned //size
    madd x21, x2, x21, x4                    // Indirizzo primo elemento
    madd x22, x2, x22, x4                    // Indirizzo secondo elemento
    mov x0, x21 //x0 destinazione primo elemento
    mov x1, x22 //x1 sorgente secondo elemento
    bl memcpy
    mov x0, x22
    adr x1, film_temp
    mov x2, film_size_aligned
    bl memcpy

    svuota_variabile_temporanea

    ldp x21, x22, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size scambia_due_elementi_nella_struttura, (. - scambia_due_elementi_nella_struttura)

.type scambio_prezzo %function
scambio_prezzo:
   
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    
    ldr x20, =film      // indirizzo struttura che contiene i film 
    ldr x22, n_film     // numero film   

    cmp x22, #0         // controllo se ci sono film presenti
    beq scambio_prezzo_error        // altrimenti salto

    cmp x22, #1         // controllo se c'è almeno una coppia di film 
    beq scambio_prezzo_error_less       // altrimenti salto


    sub x22, x22, #1    // iterare da 0 a (n_film)-1 (per evitare overflow)
    mov x23, #0         // contatore i 
    mov x0,#0
    mov x24, #0         // flag per indicare se è stato effettuato lo scambio
    
    scambio_prezzo_loop:     
        cmp x23,x22
        beq scambio_prezzo_loop_endloop 
        
        
        // Registri temporanei
        add x8, x20, offset_film_prezzo // Indirizzo del prezzo i
        add x9, x8, film_size_aligned   // Indirizzo del prezzo i+1 (prezzo successivo)

        // Ottengo i prezzi 
        ldrsw x19, [x8] // prezzo1 
        ldrsw x21, [x9] // prezzo2

        
        cmp x19, x21    // confronto tra prezzo1 e prezzo2  
        ble end_if      // altrimenti continuo ad iterare

        // metto i film nei registri x1 e x2 per poter passarli come parametri alla funzione 
        mov x0, x23
        add x1, x23, #1  // siccome è un elemento adiacente ovviamente la posizione sarà la successiva     
        bl scambia_due_elementi_nella_struttura

        mov x24, #1      // c'è stato uno scambio e il flag è settato a 1
        bl save_data  

        adr x0, fmt_scambio_effettuato
        mov x1, x23           // Argomenti per la stampa; Posizione x
        add x1, x1, #1        // aggiungo 1 perchè parte da 1-based       
        mov x2, x19           // Prezzo della posizione x
        add x3, x1, #1        // posizione y
        mov x4, x21           // prezzo posizione y
        bl printf             // stampa scambio effettuato 

        b scambio_prezzo_loop_endloop
       
        end_if:     
            add x20, x20, film_size_aligned // incremento l'indirizzo per scandire l'elemento successivo
            add x23, x23, #1                // incremento il contatore
            b scambio_prezzo_loop           // torno nel loop

    scambio_prezzo_loop_endloop:
    cmp x24, #0     // controllo se è stato effettuato uno scambio
    bne no_nessuno_scambio      // se il flag non è settato ad uno 
    adr x0, fmt_nessuno_scambio
    bl printf       // Stampa nessuno scambio
    b no_nessuno_scambio

    scambio_prezzo_error:
        adr x0, fmt_nessun_film_presente
        bl printf       // stampa per nessun film presente
        b scambio_prezzo_loop_endloop
    
    scambio_prezzo_error_less:
        adr x0, fmt_fail_less_film   // Stampa per numero insufficente di coppie 
        bl printf


    no_nessuno_scambio:

    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16      
   
    ret
    .size scambio_prezzo, (. - scambio_prezzo)

.type elimina_duplicato, %function
elimina_duplicato:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!   
    
    ldr x19, =film // in x19 carichiamo l'indirizzo della struttura in cui sono memorizzati i film 
    ldrsw x20, n_film // in x20 carichiamo il numero dei film

    cmp x20,#2 /* confrontiamo il numero dei film con il valore immediato 2 perché
                l'operazione può essere effettuata solo se ci sono più di 2 film */
    
    blt elimina_duplicato_error_less /* in caso il numero dei film non supera il numero 2, mandare
                                        un messaggio di errore e terminare l'operazione */
    
    add x19, x19, offset_film_anno // spostiamoci direttamente sul dato "anno" del primo film
    mov x21, #1 // in x21 carichiamo il contatore per il ciclo
    mov x22, #0 // in x22 carichiamo un valore che ci servirà per capire se abbiamo trovato un duplicato

    loop_elimina_duplicato:
        cmp x21, x20 // controlliamo se abbiamo finito i film da analizzare
        beq loop_elimina_duplicato_end // se si, terminiamo il ciclo con nessun duplicato trovato
        ldrsw x23, [x19], film_size_aligned // valore anno elemento attuale, incremento post-index     
        ldrsw x24, [x19] // valore anno elemento successivo

        cmp x23, x24 // confrontiamo se i due anni dei due film adiacenti sono uguali
        beq uguali // se si, andiamo nel blocco "uguali"
        add x21, x21, #1 // incremento del contatore per il ciclo

        b loop_elimina_duplicato // ricomincio il ciclo

        uguali:
            mov x22, #1 // in x22 indico con il valore immediato 1 che sono uguali
            sub x0, x19, offset_film_anno // in x0 salvo il primo film con l'anno uguale a quello successivo
            add x1, x0, film_size_aligned // in x1 vado avanti di un film che è il duplicato da eliminare

            sub x24, x20, x21 /* in x24 salvo la differenza tra n_film e il
                                    contatore per ottenere i film rimanenti */
                
            mov x4, film_size_aligned // memorizzo momentaneamente in x4 la lunghezza di un elemento intero

            mul x24, x24, x4 /* moltiplico i film rimanenti con la lunghezza di un
                                    elemento intero per ottenere la memoria di questi */
                
            mov x2, x24 // metto il risultato in x2
            bl memcpy // copio la memoria

            // decremento n_film di 1
            adr x0, n_film
            ldr w1, [x0]
            sub w1, w1, #1
            str w1, [x0]           

            bl save_data // salvo con i film aggiornati

            adr x0, fmt_eliminazione_effettuata // messaggio di operazione effettuata
            add x21, x21, #1 // incremento del contatore per il ciclo     
            mov x1, x21
            mov x2, x23
            bl printf
            
            b endif_elimina // finisce il ciclo

    loop_elimina_duplicato_end:
        cmp x22, #0 // controlla se effettivamente ha trovato un duplicato
        bne endif_elimina // se si, termina l'operazione
        adr x0, fmt_nessuna_eliminazione /* manda un messaggio che dice che
                                            non è stato trovato nessun duplicato */
        bl printf
        b endif_elimina // finisce il ciclo

    elimina_duplicato_error_less:
        adr x0, fmt_fail_less_film // manda un messaggio di errore che dice che ci sono meno di 2 film
        bl printf
        
    endif_elimina:

    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size elimina_duplicato, (. - elimina_duplicato)
