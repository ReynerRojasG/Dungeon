.MODEL SMALL
.STACK 1024

; ------------------ CONSTANTES ----------------------
SCR_W          EQU 640
SCR_H          EQU 350
IMG_W          EQU 480
IMG_H          EQU 336
LEFT_MARGIN    EQU (SCR_W - IMG_W) / 2
TOP_MARGIN     EQU (SCR_H - IMG_H) / 2
BUF_SIZE       EQU 4096
VIEW_W         EQU 160
VIEW_H         EQU 100
SCALE_FACTOR   EQU 2     ; Factor de escalado 2x
PLAYER_SIZE    EQU 16    ; Tamaño del sprite 16x16

.DATA
FILE_NAME      DB 'mapRD.txt', 0
FILE_HANDLE    DW 0
BUFFER         DB BUF_SIZE DUP(?)
BYTES_IN_BUFFER DW 0
BUF_INDEX      DW 0
END_FLAG       DB 0
X_CUR          DW 0
Y_CUR          DW 0
VIEW_X         DW 0
VIEW_Y         DW 0

MSG_OPEN_ERR   DB 'ERROR ABRIENDO EL ARCHIVO$', 0
MSG_READ_ERR   DB 'ERROR LEYENDO EL ARCHIVO$', 0
MSG_CONTROLS   DB 'WASD: Mover  Q: Salir$', 0
MSG_POSITION   DB 'Viewport: $', 0

PLAYER_SPRITE db \
'TTTTT000000TTTTT', \
'TTTT0EEEE660TTTT', \
'TTT0EEEEEE660TTT', \
'TT004444444400TT', \
'T0EEEEEEEEEEEE0T', \
'0EE6000000006EE0', \
'0E606006000006E0', \
'T06007007000060T', \
'TT000F60F60000TT', \
'TTT066666600TTTT', \
'TTTT06666040TTTT', \
'TTT046E644440TTT', \
'TT064EEE40660TTT', \
'TT06099990660TTT', \
'TTT009009900TTTT', \
'TTTT060T060TTTTT'
; ------------------ CÓDIGO PRINCIPAL ----------------------
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    CALL SET_VIDEO_MODE
    CALL OPEN_FILE
    JC OPEN_FAIL
    MOV FILE_HANDLE, AX

    CALL INIT_CURSOR
    MOV END_FLAG, 0

    ; Cargar y dibujar el mapa completo en memoria virtual
    CALL LOAD_ENTIRE_MAP

NAVIGATION_LOOP:
    CALL CLEAR_SCREEN
    CALL DRAW_VIEWPORT
    CALL DRAW_PLAYER     ; Dibujar jugador después del mapa
    CALL SHOW_INFO
    CALL WAIT_KEY
    
    CMP AL, 'q'
    JE EXIT_PROGRAM
    CMP AL, 'Q'
    JE EXIT_PROGRAM
    
    CALL PROCESS_KEY
    JMP NAVIGATION_LOOP

EXIT_PROGRAM:
    MOV BX, FILE_HANDLE
    CALL CLOSE_FILE
    JMP EXIT_OK

OPEN_FAIL:
    LEA DX, MSG_OPEN_ERR
    CALL PRINT_STR
    CALL WAIT_KEY

EXIT_OK:
    CALL RESTORE_TEXT
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

; ------------------ DIBUJO DEL JUGADOR --------------------
DRAW_PLAYER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Calcular posición del jugador en el centro del viewport
    ; Centro X = LEFT_MARGIN + (VIEW_W * SCALE_FACTOR) / 2 - (PLAYER_SIZE * SCALE_FACTOR)/2
    ; Centro Y = TOP_MARGIN + (VIEW_H * SCALE_FACTOR) / 2 - (PLAYER_SIZE * SCALE_FACTOR)/2
    
    MOV AX, VIEW_W
    SHL AX, 1           ; AX = VIEW_W * 2 (escalado)
    SHR AX, 1           ; Dividir entre 2
    MOV BX, PLAYER_SIZE
    SHL BX, 1           ; BX = PLAYER_SIZE * 2 (escalado)
    SHR BX, 1           ; Dividir entre 2
    SUB AX, BX
    ADD AX, LEFT_MARGIN
    MOV CX, AX          ; CX = X posición del jugador
    
    MOV AX, VIEW_H
    SHL AX, 1           ; AX = VIEW_H * 2 (escalado)
    SHR AX, 1           ; Dividir entre 2
    MOV BX, PLAYER_SIZE
    SHL BX, 1           ; BX = PLAYER_SIZE * 2 (escalado)
    SHR BX, 1           ; Dividir entre 2
    SUB AX, BX
    ADD AX, TOP_MARGIN
    MOV DX, AX          ; DX = Y posición del jugador
    
    ; Dibujar sprite del jugador ESCALADO
    LEA SI, PLAYER_SPRITE
    CALL DRAW_SCALED_SPRITE
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_PLAYER ENDP

; ------------------ DIBUJO DE SPRITE ESCALADO --------------------
DRAW_SCALED_SPRITE PROC
    ; SI = offset del sprite
    ; CX = X posición
    ; DX = Y posición
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV DI, DX          ; DI = Y inicial
    MOV BX, 0           ; Contador de filas
    
SCALED_SPRITE_ROW_LOOP:
    CMP BX, PLAYER_SIZE
    JE SCALED_SPRITE_DONE
    
    PUSH CX             ; Guardar X inicial
    MOV DX, DI          ; DX = Y actual
    
    MOV AH, 0           ; Contador de columnas
SCALED_SPRITE_COL_LOOP:
    CMP AH, PLAYER_SIZE
    JE SCALED_SPRITE_NEXT_ROW
    
    ; Leer carácter del sprite
    MOV AL, [SI]
    
    ; Verificar si es transparente ('T')
    CMP AL, 'T'
    JE SCALED_SKIP_PIXEL
    
    ; Si no es 'T', convertir de hexadecimal
    CALL HEX_TO_NIBBLE
    JC SCALED_SKIP_PIXEL
    
    ; Dibujar bloque escalado 2x2
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 0CH         ; Función dibujar pixel
    XOR BH, BH          ; Página 0
    
    ; Fila superior del bloque escalado
    INT 10H             ; (CX, DX)
    INC CX
    INT 10H             ; (CX+1, DX)
    
    ; Fila inferior del bloque escalado
    DEC CX
    INC DX
    INT 10H             ; (CX, DX+1)
    INC CX
    INT 10H             ; (CX+1, DX+1)
    
    DEC DX              ; Restaurar Y original
    POP DX
    POP CX
    POP BX
    POP AX
    
SCALED_SKIP_PIXEL:
    INC SI              ; Siguiente carácter del sprite
    ADD CX, 2           ; Siguiente columna (escalado 2x)
    INC AH              ; Incrementar contador de columnas
    JMP SCALED_SPRITE_COL_LOOP

SCALED_SPRITE_NEXT_ROW:
    POP CX              ; Restaurar X inicial
    ADD DI, 2           ; Siguiente fila (escalado 2x)
    INC BX              ; Incrementar contador de filas
    JMP SCALED_SPRITE_ROW_LOOP

SCALED_SPRITE_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_SCALED_SPRITE ENDP

; ------------------ CARGA COMPLETA DEL MAPA ------------------
LOAD_ENTIRE_MAP PROC
    ; Reiniciar posición del cursor para carga completa
    MOV WORD PTR X_CUR, 0
    MOV WORD PTR Y_CUR, 0
    
READ_MAP_LOOP:
    CALL READ_CHUNK
    CMP BYTES_IN_BUFFER, 0
    JE MAP_LOADED

    CALL PARSE_MAP_DATA
    CMP END_FLAG, 1
    JNE READ_MAP_LOOP

MAP_LOADED:
    ; Reiniciar file handle para posibles re-lecturas
    MOV AX, FILE_HANDLE
    PUSH AX
    CALL CLOSE_FILE
    CALL OPEN_FILE
    MOV FILE_HANDLE, AX
    POP AX
    RET
LOAD_ENTIRE_MAP ENDP

; ------------------ PARSER PARA CARGA --------------------
PARSE_MAP_DATA PROC
NEXT_MAP_BYTE:
    MOV BX, BUF_INDEX
    CMP BX, BYTES_IN_BUFFER
    JAE MAP_DONE

    MOV SI, BX
    MOV AL, BUFFER[SI]
    INC BX
    MOV BUF_INDEX, BX

    MOV DL, AL
    CALL HEX_TO_NIBBLE
    JNC IS_MAP_PIXEL

    MOV AL, DL
    CMP AL, '@'
    JE MAP_END_LINE
    CMP AL, '%'
    JE MAP_END_FILE
    CMP AL, 13
    JE NEXT_MAP_BYTE
    CMP AL, 10
    JE NEXT_MAP_BYTE
    CMP AL, ' '
    JE NEXT_MAP_BYTE
    JMP NEXT_MAP_BYTE

IS_MAP_PIXEL:
    ; Aquí podrías almacenar el pixel en un buffer de mapa completo
    ; Por ahora solo avanzamos las coordenadas
    JMP MAP_STEP_X

MAP_STEP_X:
    INC WORD PTR X_CUR
    JMP NEXT_MAP_BYTE

MAP_END_LINE:
    CALL MAP_NEXT_ROW
    JMP NEXT_MAP_BYTE

MAP_END_FILE:
    MOV END_FLAG, 1

MAP_DONE:
    RET
PARSE_MAP_DATA ENDP

MAP_NEXT_ROW PROC
    INC WORD PTR Y_CUR
    MOV WORD PTR X_CUR, 0
    RET
MAP_NEXT_ROW ENDP

; ------------------ DIBUJO DEL VIEWPORT --------------------
DRAW_VIEWPORT PROC
    ; Esta función dibuja solo la porción visible del mapa
    ; basado en VIEW_X y VIEW_Y
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Reiniciar posición del cursor para dibujar viewport
    MOV WORD PTR X_CUR, 0
    MOV WORD PTR Y_CUR, 0
    MOV END_FLAG, 0
    
    ; Posicionar archivo al inicio
    MOV BX, FILE_HANDLE
    CALL CLOSE_FILE
    CALL OPEN_FILE
    MOV FILE_HANDLE, AX

DRAW_LOOP:
    CALL READ_CHUNK
    CMP BYTES_IN_BUFFER, 0
    JE DRAW_DONE

    CALL PARSE_AND_DRAW_VIEWPORT
    CMP END_FLAG, 1
    JNE DRAW_LOOP

DRAW_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_VIEWPORT ENDP

; ------------------ PARSER PARA VIEWPORT --------------------
PARSE_AND_DRAW_VIEWPORT PROC
NEXT_VIEW_BYTE:
    MOV BX, BUF_INDEX
    CMP BX, BYTES_IN_BUFFER
    JAE VIEW_DONE

    MOV SI, BX
    MOV AL, BUFFER[SI]
    INC BX
    MOV BUF_INDEX, BX

    MOV DL, AL
    CALL HEX_TO_NIBBLE
    JNC IS_VIEW_PIXEL

    MOV AL, DL
    CMP AL, '@'
    JE VIEW_END_LINE
    CMP AL, '%'
    JE VIEW_END_FILE
    CMP AL, 13
    JE NEXT_VIEW_BYTE
    CMP AL, 10
    JE NEXT_VIEW_BYTE
    CMP AL, ' '
    JE NEXT_VIEW_BYTE
    JMP NEXT_VIEW_BYTE

IS_VIEW_PIXEL:
    ; Verificar si el pixel está dentro del viewport
    MOV BX, X_CUR
    CMP BX, VIEW_X
    JB VIEW_STEP_X
    MOV CX, BX
    SUB CX, VIEW_X
    CMP CX, VIEW_W
    JAE VIEW_STEP_X
    
    MOV BX, Y_CUR
    CMP BX, VIEW_Y
    JB VIEW_STEP_X
    MOV DX, BX
    SUB DX, VIEW_Y
    CMP DX, VIEW_H
    JAE VIEW_STEP_X
    
    ; Dibujar pixel (AL ya tiene el color)
    CALL DRAW_SCALED_PIXEL

VIEW_STEP_X:
    INC WORD PTR X_CUR
    JMP NEXT_VIEW_BYTE

VIEW_END_LINE:
    CALL VIEW_NEXT_ROW
    JMP NEXT_VIEW_BYTE

VIEW_END_FILE:
    MOV END_FLAG, 1

VIEW_DONE:
    RET
PARSE_AND_DRAW_VIEWPORT ENDP

; ------------------ DIBUJO DE PIXEL ESCALADO CORREGIDO --------------------
DRAW_SCALED_PIXEL PROC
    ; AL = color
    ; CX = X relativo al viewport
    ; DX = Y relativo al viewport
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Calcular posición base en pantalla
    MOV SI, CX          ; Guardar X original
    SHL CX, 1           ; CX = X * 2 (escalado 2x)
    SHL DX, 1           ; DX = Y * 2 (escalado 2x)
    
    ADD CX, LEFT_MARGIN
    ADD DX, TOP_MARGIN
    
    ; Dibujar bloque 2x2
    MOV AH, 0CH
    XOR BH, BH
    
    ; Fila superior
    INT 10H             ; (CX, DX)
    INC CX
    INT 10H             ; (CX+1, DX)
    
    ; Fila inferior
    DEC CX
    INC DX
    INT 10H             ; (CX, DX+1)
    INC CX
    INT 10H             ; (CX+1, DX+1)
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_SCALED_PIXEL ENDP

VIEW_NEXT_ROW PROC
    INC WORD PTR Y_CUR
    MOV WORD PTR X_CUR, 0
    RET
VIEW_NEXT_ROW ENDP

; ------------------ NAVEGACIÓN --------------------
PROCESS_KEY PROC
    CMP AL, 'w'
    JE MOVE_UP
    CMP AL, 'W'
    JE MOVE_UP
    CMP AL, 's'
    JE MOVE_DOWN
    CMP AL, 'S'
    JE MOVE_DOWN
    CMP AL, 'a'
    JE MOVE_LEFT
    CMP AL, 'A'
    JE MOVE_LEFT
    CMP AL, 'd'
    JE MOVE_RIGHT
    CMP AL, 'D'
    JE MOVE_RIGHT
    RET

MOVE_UP:
    CMP VIEW_Y, 0
    JE NO_MOVE
    SUB VIEW_Y, 10
    RET

MOVE_DOWN:
    MOV AX, VIEW_Y
    ADD AX, VIEW_H
    ADD AX, 10
    CMP AX, IMG_H
    JAE NO_MOVE
    ADD VIEW_Y, 10
    RET

MOVE_LEFT:
    CMP VIEW_X, 0
    JE NO_MOVE
    SUB VIEW_X, 10
    RET

MOVE_RIGHT:
    MOV AX, VIEW_X
    ADD AX, VIEW_W
    ADD AX, 10
    CMP AX, IMG_W
    JAE NO_MOVE
    ADD VIEW_X, 10
    RET

NO_MOVE:
    RET
PROCESS_KEY ENDP

; ------------------ INTERFAZ --------------------
SHOW_INFO PROC
    ; Mostrar información en modo texto sobre el gráfico
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    CALL DRAW_TEXT_INFO
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_INFO ENDP

DRAW_TEXT_INFO PROC
    ; Usar funciones BIOS para dibujar texto en modo gráfico
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 1
    INT 10h
    
    LEA SI, MSG_POSITION
    CALL PRINT_GRAPHIC_TEXT
    
    ; Mostrar coordenadas del viewport
    MOV AX, VIEW_X
    CALL PRINT_NUMBER
    MOV AL, ','
    CALL PRINT_CHAR
    MOV AX, VIEW_Y
    CALL PRINT_NUMBER
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 23
    MOV DL, 1
    INT 10h
    
    LEA SI, MSG_CONTROLS
    CALL PRINT_GRAPHIC_TEXT
    
    RET
DRAW_TEXT_INFO ENDP

PRINT_GRAPHIC_TEXT PROC
    ; Imprimir texto en modo gráfico
    MOV AH, 0Eh
    XOR BH, BH
PRINT_LOOP:
    LODSB
    CMP AL, '$'
    JE PRINT_DONE
    INT 10h
    JMP PRINT_LOOP
PRINT_DONE:
    RET
PRINT_GRAPHIC_TEXT ENDP

PRINT_NUMBER PROC
    ; Imprimir número en AX
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0
    MOV BX, 10
DIV_LOOP:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ DIV_LOOP
    
PRINT_LOOP_NUM:
    POP AX
    ADD AL, '0'
    MOV AH, 0Eh
    INT 10h
    LOOP PRINT_LOOP_NUM
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

PRINT_CHAR PROC
    ; Imprimir carácter en AL
    MOV AH, 0Eh
    INT 10h
    RET
PRINT_CHAR ENDP

CLEAR_SCREEN PROC
    MOV AX, 0600h
    MOV BH, 0
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h
    RET
CLEAR_SCREEN ENDP

; ------------------ VIDEO ----------------------
SET_VIDEO_MODE PROC
    MOV AX, 0010H
    INT 10H
    RET
SET_VIDEO_MODE ENDP

RESTORE_TEXT PROC
    MOV AX, 0003H
    INT 10H
    RET
RESTORE_TEXT ENDP

; ------------------ ARCHIVO --------------------
OPEN_FILE PROC
    MOV DX, OFFSET FILE_NAME
    MOV AX, 3D00H
    INT 21H
    RET
OPEN_FILE ENDP

CLOSE_FILE PROC
    MOV AH, 3EH
    INT 21H
    RET
CLOSE_FILE ENDP

READ_CHUNK PROC
    MOV BX, FILE_HANDLE
    MOV DX, OFFSET BUFFER
    MOV CX, BUF_SIZE
    MOV AH, 3FH
    INT 21H
    JC READ_ERR
    MOV BYTES_IN_BUFFER, AX
    MOV WORD PTR BUF_INDEX, 0
    RET

READ_ERR:
    MOV BYTES_IN_BUFFER, 0
    MOV WORD PTR BUF_INDEX, 0
    LEA DX, MSG_READ_ERR
    CALL PRINT_STR
    RET
READ_CHUNK ENDP

; ------------------ CONVERSOR HEX --------------------
HEX_TO_NIBBLE PROC
    CMP AL, '0'
    JB NOT_HEX
    CMP AL, '9'
    JBE DEC_DIGIT
    CMP AL, 'A'
    JB CHK_LOWER
    CMP AL, 'F'
    JBE UP_DIGIT
    JMP CHK_LOWER

DEC_DIGIT:
    SUB AL, '0'
    CLC
    RET

UP_DIGIT:
    SUB AL, 'A'
    ADD AL, 10
    CLC
    RET

CHK_LOWER:
    CMP AL, 'a'
    JB NOT_HEX
    CMP AL, 'f'
    JBE LO_DIGIT
    JMP NOT_HEX

LO_DIGIT:
    SUB AL, 'a'
    ADD AL, 10
    CLC
    RET

NOT_HEX:
    STC
    RET
HEX_TO_NIBBLE ENDP

; ------------------ FILAS / CURSOR --------------------
INIT_CURSOR PROC
    MOV WORD PTR X_CUR, 0
    MOV WORD PTR Y_CUR, 0
    RET
INIT_CURSOR ENDP

; ------------------ ENTRADA / SALIDA --------------------
WAIT_KEY PROC
    MOV AH, 00H
    INT 16H
    RET
WAIT_KEY ENDP

PRINT_STR PROC
    MOV AH, 09H
    INT 21H
    RET
PRINT_STR ENDP

END MAIN