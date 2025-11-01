.MODEL SMALL
.STACK 100H

.DATA
FILENAME     DB 'ejemplo.txt', 0
FILE_HANDLE  DW ?
BUFFER       DB 200 DUP(?)         ; Suficiente para el contenido
MATRIX       DB 18 DUP(?)          ; 3 filas × 6 columnas
CURSOR_ROW   DB 0
CURSOR_COL   DB 0
NUEVA_LINEA  DB 13, 10, '$'
MSG_POSICION DB 'Posicion: $'
MSG_SALIR    DB 'Presiona Q para salir$'

.CODE
MAIN PROC
    MOV AX, @data
    MOV DS, AX

    CALL ABRIR_ARCHIVO
    CALL LEER_ARCHIVO
    CALL PARSEAR_BUFFER

    ; Inicializar cursor en una posición que sea 1 (fila 0, columna 0)
    MOV CURSOR_ROW, 0
    MOV CURSOR_COL, 0

    ; Bucle principal de navegación
NAVEGACION:
    CALL LIMPIAR_PANTALLA
    CALL MOSTRAR_INTERFAZ
    CALL LEER_TECLA
    CMP AL, 'q'         ; Salir con Q
    JE SALIR
    CMP AL, 'Q'
    JE SALIR
    CALL PROCESAR_TECLA
    JMP NAVEGACION

SALIR:
    MOV AX, 4C00h
    INT 21h
MAIN ENDP

; ------------------ ABRIR ARCHIVO ------------------
ABRIR_ARCHIVO PROC
    MOV AH, 3Dh         ; Abrir archivo
    MOV AL, 0           ; Modo lectura
    LEA DX, FILENAME
    INT 21h
    JC ERROR
    MOV FILE_HANDLE, AX
    RET
ERROR:
    MOV AH, 9
    LEA DX, NUEVA_LINEA
    INT 21h
    MOV AX, 4C01h
    INT 21h
ABRIR_ARCHIVO ENDP

; ------------------ LEER ARCHIVO ------------------
LEER_ARCHIVO PROC
    MOV AH, 3Fh         ; Leer archivo
    MOV BX, FILE_HANDLE
    LEA DX, BUFFER
    MOV CX, 200         ; Leer hasta 200 bytes
    INT 21h
    RET
LEER_ARCHIVO ENDP

; ------------------ PARSEAR BUFFER ------------------
PARSEAR_BUFFER PROC
    LEA SI, BUFFER
    LEA DI, MATRIX
    MOV CX, 0           ; Contador de números
    MOV BX, 0           ; Acumulador de número

PARSE_LOOP:
    LODSB               ; AL = siguiente byte
    CMP AL, 0
    JE PARSE_DONE

    CMP AL, ','         ; Fin de número
    JE GUARDAR_NUMERO
    CMP AL, 13          ; CR
    JE GUARDAR_NUMERO
    CMP AL, 10          ; LF
    JE GUARDAR_NUMERO

    ; Convertir carácter a dígito
    SUB AL, '0'
    MOV AH, 0
    
    ; BX = BX * 10 + AX
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX              ; AX = BX * 10
    MOV BX, AX
    POP AX
    ADD BL, AL
    
    JMP PARSE_LOOP

GUARDAR_NUMERO:
    ; Solo guardar si hemos acumulado un número
    CMP CX, 18
    JGE PARSE_DONE
    
    MOV [DI], BL        ; Guardar el número en la matriz
    INC DI
    INC CX
    
    MOV BX, 0           ; Reset acumulador
    
    ; Saltar caracteres de nueva línea adicionales
    CMP AL, 13
    JNE CHECK_LF
    LODSB               ; Saltar el LF después del CR
    JMP PARSE_LOOP
    
CHECK_LF:
    CMP AL, 10
    JNE PARSE_LOOP
    JMP PARSE_LOOP

PARSE_DONE:
    RET
PARSEAR_BUFFER ENDP

; ------------------ MOSTRAR VALOR ACTUAL ------------------
MOSTRAR_VALOR_ACTUAL PROC
    MOV AL, CURSOR_ROW
    MOV BL, 6           ; Número de columnas
    MUL BL              ; AX = fila * columnas
    ADD AL, CURSOR_COL
    LEA BX, MATRIX
    MOV SI, AX
    MOV AL, [BX + SI]   ; Obtener valor de la matriz
    
    CALL MOSTRAR_NUMERO ; Reutilizar la rutina existente
    RET
MOSTRAR_VALOR_ACTUAL ENDP

; ------------------ MOSTRAR INTERFAZ ------------------
MOSTRAR_INTERFAZ PROC
    ; Mostrar mensaje de posición
    MOV AH, 9
    LEA DX, MSG_POSICION
    INT 21h
    
    ; Mostrar coordenadas
    MOV AL, CURSOR_ROW
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 2
    INT 21h
    
    MOV DL, ','
    INT 21h
    
    MOV AL, CURSOR_COL
    ADD AL, '0'
    MOV DL, AL
    INT 21h
    
    MOV DL, ' '
    INT 21h
    MOV DL, '-'
    INT 21h
    MOV DL, ' '
    INT 21h
    
    ; Mostrar valor en esa posición
    CALL MOSTRAR_VALOR_ACTUAL
    
    CALL MOSTRAR_NUEVA_LINEA
    CALL MOSTRAR_NUEVA_LINEA
    
    ; Mostrar controles
    MOV AH, 9
    LEA DX, MSG_SALIR
    INT 21h
    
    CALL MOSTRAR_NUEVA_LINEA
    CALL MOSTRAR_NUEVA_LINEA
    
    ; Mostrar matriz completa para referencia
    CALL MOSTRAR_MATRIZ_COMPLETA
    
    RET
MOSTRAR_INTERFAZ ENDP

; ------------------ MOSTRAR MATRIZ COMPLETA ------------------
MOSTRAR_MATRIZ_COMPLETA PROC
    LEA SI, MATRIX
    MOV CH, 0           ; Contador de filas
    MOV CL, 0           ; Contador de columnas
    
FILA_LOOP:
    MOV AL, [SI]
    CALL MOSTRAR_NUMERO
    
    INC SI
    INC CL
    
    ; Verificar si es el final de la fila
    CMP CL, 6
    JL MOSTRAR_COMA
    
    ; Fin de fila
    CALL MOSTRAR_NUEVA_LINEA
    MOV CL, 0
    INC CH
    CMP CH, 3
    JL FILA_LOOP
    JMP FIN_MATRIZ
    
MOSTRAR_COMA:
    MOV DL, ','
    MOV AH, 2
    INT 21h
    MOV DL, ' '
    INT 21h
    JMP FILA_LOOP
    
FIN_MATRIZ:
    RET
MOSTRAR_MATRIZ_COMPLETA ENDP

; ------------------ LEER TECLA ------------------
LEER_TECLA PROC
    MOV AH, 8           ; Leer tecla sin eco
    INT 21h
    RET
LEER_TECLA ENDP

; ------------------ PROCESAR TECLA ------------------
PROCESAR_TECLA PROC
    CMP AL, 'w'
    JE MOVER_ARRIBA
    CMP AL, 'W'
    JE MOVER_ARRIBA
    CMP AL, 's'
    JE MOVER_ABAJO
    CMP AL, 'S'
    JE MOVER_ABAJO
    CMP AL, 'a'
    JE MOVER_IZQUIERDA
    CMP AL, 'A'
    JE MOVER_IZQUIERDA
    CMP AL, 'd'
    JE MOVER_DERECHA
    CMP AL, 'D'
    JE MOVER_DERECHA
    RET

MOVER_ARRIBA:
    CMP CURSOR_ROW, 0
    JE NO_MOVER_ARRIBA   ; Salto corto a etiqueta local
    
    ; Verificar si la posición de arriba es 1
    MOV AL, CURSOR_ROW
    DEC AL
    MOV BL, 6
    MUL BL
    ADD AL, CURSOR_COL
    LEA BX, MATRIX
    MOV SI, AX
    CMP BYTE PTR [BX + SI], 1
    JNE NO_MOVER_ARRIBA  ; Salto corto a etiqueta local
    DEC CURSOR_ROW
    RET

NO_MOVER_ARRIBA:
    RET

MOVER_ABAJO:
    CMP CURSOR_ROW, 2
    JE NO_MOVER_ABAJO    ; Salto corto a etiqueta local
    
    ; Verificar si la posición de abajo es 1
    MOV AL, CURSOR_ROW
    INC AL
    MOV BL, 6
    MUL BL
    ADD AL, CURSOR_COL
    LEA BX, MATRIX
    MOV SI, AX
    CMP BYTE PTR [BX + SI], 1
    JNE NO_MOVER_ABAJO   ; Salto corto a etiqueta local
    INC CURSOR_ROW
    RET

NO_MOVER_ABAJO:
    RET

MOVER_IZQUIERDA:
    CMP CURSOR_COL, 0
    JE NO_MOVER_IZQUIERDA ; Salto corto a etiqueta local
    
    ; Verificar si la posición de la izquierda es 1
    MOV AL, CURSOR_ROW
    MOV BL, 6
    MUL BL
    ADD AL, CURSOR_COL
    DEC AL
    LEA BX, MATRIX
    MOV SI, AX
    CMP BYTE PTR [BX + SI], 1
    JNE NO_MOVER_IZQUIERDA ; Salto corto a etiqueta local
    DEC CURSOR_COL
    RET

NO_MOVER_IZQUIERDA:
    RET

MOVER_DERECHA:
    CMP CURSOR_COL, 5
    JE NO_MOVER_DERECHA  ; Salto corto a etiqueta local
    
    ; Verificar si la posición de la derecha es 1
    MOV AL, CURSOR_ROW
    MOV BL, 6
    MUL BL
    ADD AL, CURSOR_COL
    INC AL
    LEA BX, MATRIX
    MOV SI, AX
    CMP BYTE PTR [BX + SI], 1
    JNE NO_MOVER_DERECHA ; Salto corto a etiqueta local
    INC CURSOR_COL
    RET

NO_MOVER_DERECHA:
    RET
PROCESAR_TECLA ENDP

; ------------------ LIMPIAR PANTALLA ------------------
LIMPIAR_PANTALLA PROC
    MOV AX, 0600h      ; Función 06h - Scroll up
    MOV BH, 07h        ; Atributo (gris sobre negro)
    MOV CX, 0000h      ; Esquina superior izquierda
    MOV DX, 184Fh      ; Esquina inferior derecha
    INT 10h
    
    ; Posicionar cursor en (0,0)
    MOV AH, 02h
    MOV BH, 00h
    MOV DX, 0000h
    INT 10h
    RET
LIMPIAR_PANTALLA ENDP

MOSTRAR_NUEVA_LINEA PROC
    MOV AH, 9
    LEA DX, NUEVA_LINEA
    INT 21h
    RET
MOSTRAR_NUEVA_LINEA ENDP

MOSTRAR_NUMERO PROC
    MOV AH, 0
    CMP AL, 10
    JL SOLO_UNIDAD

    MOV BL, 10
    DIV BL
    MOV BH, AH

    ADD AL, '0'
    MOV DL, AL
    MOV AH, 2
    INT 21h

    MOV DL, BH
    ADD DL, '0'
    MOV AH, 2
    INT 21h
    RET

SOLO_UNIDAD:
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 2
    INT 21h
    RET
MOSTRAR_NUMERO ENDP

END MAIN