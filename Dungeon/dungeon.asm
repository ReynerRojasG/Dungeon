.MODEL SMALL
.STACK 1024

; ------------------ CONSTANTES ----------------------
SCR_W          EQU 640
SCR_H          EQU 350
IMG_W          EQU 480
IMG_H          EQU 336
LEFT_MARGIN    EQU (SCR_W - IMG_W) / 2
TOP_MARGIN     EQU (SCR_H - IMG_H) / 2
VIEW_W         EQU 176
VIEW_H         EQU 112
SCALE_FACTOR   EQU 2     ; Factor de escalado 2x
PLAYER_SIZE    EQU 16    ; Tamaño del sprite 16x16

.DATA
FILE_NAME      DB 'mapRD.txt', 0
FILE_HANDLE    DW 0
BUFFER         DB 4096 DUP(?)
BYTES_IN_BUFFER DW 0
BUF_INDEX      DW 0
END_FLAG       DB 0
; ------------------ COORDENADAS --------------------
X_CUR          DW 0
Y_CUR          DW 0
VIEW_X         DW 0
VIEW_Y         DW 0

NEW_VIEW_X    DW 0       ; Nueva posición X propuesta
NEW_VIEW_Y    DW 0       ; Nueva posición Y propuesta
CHECK_X       DW 0       ; Posición X para verificar color
CHECK_Y       DW 0       ; Posición Y para verificar color
; ------------------ ITEM: MONEDAS --------------------
COIN1_POSX    DW 32
COIN1_POSY    DW 64

COIN2_POSX    DW 48
COIN2_POSY    DW 16

COIN3_POSX    DW 176
COIN3_POSY    DW 32

COIN4_POSX    DW 32
COIN4_POSY    DW 176

COIN5_POSX    DW 96
COIN5_POSY    DW 176

;ESTADOS DE LAS MONEDAS:
COIN1_COLLECTED DB 0
COIN2_COLLECTED DB 0
COIN3_COLLECTED DB 0
COIN4_COLLECTED DB 0
COIN5_COLLECTED DB 0

; ------------------ ITEM: ESPADAS --------------------
SWORD1_POSX   DW 64
SWORD1_POSY   DW 128

SWORD2_POSX   DW 144
SWORD2_POSY   DW 48

SWORD3_POSX   DW 208
SWORD3_POSY   DW 64

SWORD4_POSX   DW 80
SWORD4_POSY   DW 208

SWORD5_POSX   DW 288 
SWORD5_POSY   DW 112 

;ESTADOS DE LAS ESPADAS:
SWORD1_COLLECTED DB 0
SWORD2_COLLECTED DB 0
SWORD3_COLLECTED DB 0
SWORD4_COLLECTED DB 0
SWORD5_COLLECTED DB 0

; ------------------ ITEM: LLAVES --------------------
KEY1_POSX     DW 112
KEY1_POSY     DW 144

KEY2_POSX     DW 144
KEY2_POSY     DW 192

KEY3_POSX     DW 224
KEY3_POSY     DW 208

KEY4_POSX     DW 224
KEY4_POSY     DW 160

KEY5_POSX     DW 256
KEY5_POSY     DW 64

;ESTADOS DE LAS LLAVES:
KEY1_COLLECTED DB 0
KEY2_COLLECTED DB 0
KEY3_COLLECTED DB 0
KEY4_COLLECTED DB 0
KEY5_COLLECTED DB 0

; ------------------ CONTADOR DE ITEMS --------------------
COIN_COUNT DW 0
SWORD_COUNT DW 0
KEY_COUNT  DW 0

TOTAL_ITEMS EQU 15      ; 5 monedas + 5 espadas + 5 llaves
PROGRESS_VALUE DW 0     ; Valor del progreso (0-100)
PROGRESS_INT DW 0       ; Parte entera del progreso
PROGRESS_DEC DW 0       ; Parte decimal del progreso
; ------------------ MENSAJES --------------------
MSG_OPEN_ERR   DB 'ERROR ABRIENDO EL ARCHIVO$', 0
MSG_READ_ERR   DB 'ERROR LEYENDO EL ARCHIVO$', 0

MSG_CONTROLS   DB 'WASD: Mover  Q: Salir$', 0
MSG_POSITION   DB 'Viewport: $', 0
MSG_ITEMS_COINS DB 'Monedas: $', 0
MSG_ITEMS_SWORDS DB 'Espadas: $', 0  
MSG_ITEMS_KEYS  DB 'Llaves: $', 0
MSG_PROGRESS  DB 'Progreso: $', 0
MSG_VICTORIA DB 'VICTORIA! Has recolectado todos los items minimos$', 0

; ------------------ VARIABLES TEMPORALES --------------------
TEMP_COLOR    DB 0FFh    ; Almacena temporalmente el color encontrado
TEMP_X        DW 0       ; Posición X temporal para búsqueda
TEMP_Y        DW 0       ; Posición Y temporal para búsqueda

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
    ; Inicializar progreso a 0
    MOV PROGRESS_VALUE, 0
    MOV PROGRESS_INT, 0
    MOV PROGRESS_DEC, 0
    ; Cargar y dibujar el mapa completo en memoria virtual
    CALL LOAD_ENTIRE_MAP

NAVIGATION_LOOP:
    ; Verificar condición de victoria
    CALL CHECK_VICTORY_CONDITION
    CMP AX, 1
    JE VICTORY_SCREEN
    
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

VICTORY_SCREEN:
    CALL SHOW_VICTORY
    CALL WAIT_KEY
    JMP EXIT_PROGRAM

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

    CMP END_FLAG, 1
    JNE READ_MAP_LOOP

MAP_LOADED:
    RET
LOAD_ENTIRE_MAP ENDP

; ------------------ DIBUJO DEL VIEWPORT --------------------
DRAW_VIEWPORT PROC
    ; Esta función dibuja solo la porción visible del mapa basado en VIEW_X y VIEW_Y
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
    CALL REWIND_FILE

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

; ------------------ DIBUJO DE PIXEL ESCALADO --------------------
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
    ; Guardar la tecla presionada
    MOV AH, 0
    PUSH AX
    
    ; Primero calcular la nueva posición propuesta
    MOV AX, VIEW_X
    MOV NEW_VIEW_X, AX
    MOV AX, VIEW_Y
    MOV NEW_VIEW_Y, AX
    
    ; Restaurar la tecla
    POP AX
    
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
    CMP NEW_VIEW_Y, 0
    JNE UP_CAN_MOVE
    RET
UP_CAN_MOVE:
    SUB NEW_VIEW_Y, 16
    MOV AX, VIEW_Y
    ADD AX, 48 - 16
    MOV CHECK_Y, AX
    MOV AX, VIEW_X
    ADD AX, 80
    MOV CHECK_X, AX
    JMP CHECK_COLOR_AND_MOVE

MOVE_DOWN:
    MOV AX, NEW_VIEW_Y
    ADD AX, VIEW_H
    ADD AX, 16
    CMP AX, IMG_H
    JB DOWN_CAN_MOVE
    RET
DOWN_CAN_MOVE:
    ADD NEW_VIEW_Y, 16
    MOV AX, VIEW_Y
    ADD AX, 48 + 16
    MOV CHECK_Y, AX
    MOV AX, VIEW_X
    ADD AX, 80
    MOV CHECK_X, AX
    JMP CHECK_COLOR_AND_MOVE

MOVE_LEFT:
    CMP NEW_VIEW_X, 0
    JNE LEFT_CAN_MOVE
    RET
LEFT_CAN_MOVE:
    SUB NEW_VIEW_X, 16
    MOV AX, VIEW_Y
    ADD AX, 48
    MOV CHECK_Y, AX
    MOV AX, VIEW_X
    ADD AX, 80 - 16
    MOV CHECK_X, AX
    JMP CHECK_COLOR_AND_MOVE

MOVE_RIGHT:
    MOV AX, NEW_VIEW_X
    ADD AX, VIEW_W
    ADD AX, 16
    CMP AX, IMG_W
    JB RIGHT_CAN_MOVE
    RET
RIGHT_CAN_MOVE:
    ADD NEW_VIEW_X, 16
    MOV AX, VIEW_Y
    ADD AX, 48
    MOV CHECK_Y, AX
    MOV AX, VIEW_X
    ADD AX, 80 + 16
    MOV CHECK_X, AX
    JMP CHECK_COLOR_AND_MOVE

CHECK_COLOR_AND_MOVE:
    ; Verificar el color en la posición de destino
    MOV AX, CHECK_Y
    MOV BX, CHECK_X
    CALL CHECK_COLOR_AT_POSITION
    
    ; Comparar con los colores válidos (8=gris oscuro, 7=gris claro, 14=amarillo)
    CMP AL, 8          ; Gris oscuro
    JE COLOR_VALID
    CMP AL, 7          ; Gris claro  
    JE COLOR_VALID
    CMP AL, 14         ; Amarillo
    JE COLOR_VALID 
    JMP COLOR_INVALID  ; Si no es ninguno de los válidos

COLOR_VALID:
    ; Color válido - actualizar posición
    MOV AX, NEW_VIEW_X
    MOV VIEW_X, AX
    MOV AX, NEW_VIEW_Y
    MOV VIEW_Y, AX
    CALL COLLECT_ITEM

COLOR_INVALID:
    ; REPOSICIONAR ARCHIVO para que DRAW_TEXT_INFO funcione correctamente
    CALL REWIND_FILE
    MOV WORD PTR X_CUR, 0
    MOV WORD PTR Y_CUR, 0
    MOV WORD PTR BUF_INDEX, 0
    MOV BYTES_IN_BUFFER, 0
    MOV END_FLAG, 0
    RET
PROCESS_KEY ENDP

; ------------------ INTERFAZ DE TEXTO --------------------
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
    ; Mostrar posición del viewport (línea 21 - más arriba)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 21
    MOV DL, 1
    INT 10h
    
    LEA SI, MSG_POSITION
    CALL PRINT_GRAPHIC_TEXT
    
    MOV AX, VIEW_X
    CALL PRINT_NUMBER
    MOV AL, ','
    CALL PRINT_CHAR
    MOV AX, VIEW_Y
    CALL PRINT_NUMBER
    
    ; Mostrar progreso debajo de viewport (línea 22)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 1
    INT 10h
    LEA SI, MSG_PROGRESS
    CALL PRINT_GRAPHIC_TEXT    
    ; Mostrar parte entera del progreso
    MOV AX, PROGRESS_INT
    CALL PRINT_NUMBER

    ; Mostrar símbolo de porcentaje
    MOV AL, '%'
    CALL PRINT_CHAR
    
    ; Verificar si hay monedas recolectadas
    CMP COIN_COUNT, 0
    JE MOSTRAR_ESPADAS    ; Si es 0, saltar a espadas
    ; Mostrar monedas a la derecha (columna 40)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 21
    MOV DL, 40
    INT 10h
    
    LEA SI, MSG_ITEMS_COINS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, COIN_COUNT
    CALL PRINT_NUMBER

MOSTRAR_ESPADAS:

    ; Verificar si hay espadas recolectadas
    CMP SWORD_COUNT, 0
    JE MOSTRAR_LLAVES     ; Si es 0, saltar a llaves
    ; Mostrar espadas a la derecha (línea 22)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 40
    INT 10h
    LEA SI, MSG_ITEMS_SWORDS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, SWORD_COUNT
    CALL PRINT_NUMBER

MOSTRAR_LLAVES:
    ; Verificar si hay llaves recolectadas
    CMP KEY_COUNT, 0
    JE FIN_MOSTRAR_ITEMS  ; Si es 0, saltar al final
    ; Mostrar llaves a la derecha (línea 23)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 23
    MOV DL, 40
    INT 10h
    
    LEA SI, MSG_ITEMS_KEYS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, KEY_COUNT
    CALL PRINT_NUMBER
    FIN_MOSTRAR_ITEMS:
    ; Mostrar controles (línea 24)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 24
    MOV DL, 1
    INT 10h
    
    LEA SI, MSG_CONTROLS
    CALL PRINT_GRAPHIC_TEXT
    
    RET
DRAW_TEXT_INFO ENDP

; ------------------ VERIFICACIÓN DE COLOR --------------------
CHECK_COLOR_AT_POSITION PROC
    ; AX = Y tile position, BX = X tile position
    ; Returns: AL = color del centro del tile (posición 8,8)
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Calcular la posición del centro del tile (8,8)
    ADD AX, 8
    ADD BX, 8
    
    ; Llamar a la función que lee un píxel individual
    CALL CHECK_SINGLE_COLOR_AT_POSITION
    
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CHECK_COLOR_AT_POSITION ENDP

; ------------------ VERIFICACIÓN DE COLOR INDIVIDUAL --------------------
CHECK_SINGLE_COLOR_AT_POSITION PROC
    ; AX = Y position, BX = X position
    ; Returns: AL = color at that position (0-15) or 0xFF if error
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Variables para almacenar el color encontrado
    MOV BYTE PTR [TEMP_COLOR], 0FFh
    
    ; Usar variables temporales para la búsqueda
    MOV [TEMP_X], BX
    MOV [TEMP_Y], AX
    
    ; Guardar estado actual del archivo
    PUSH WORD PTR X_CUR
    PUSH WORD PTR Y_CUR
    PUSH WORD PTR BUF_INDEX
    PUSH WORD PTR BYTES_IN_BUFFER
    PUSH AX                    ; Guardar END_FLAG temporalmente en AX
    MOV AL, END_FLAG
    PUSH AX
    
    ; Reiniciar para búsqueda
    MOV WORD PTR X_CUR, 0
    MOV WORD PTR Y_CUR, 0
    MOV WORD PTR BUF_INDEX, 0
    MOV BYTES_IN_BUFFER, 0
    MOV END_FLAG, 0
    
    ; Posicionar archivo al inicio sin cerrarlo
    CALL REWIND_FILE

SCAN_FOR_POSITION:
    CALL READ_CHUNK
    CMP BYTES_IN_BUFFER, 0
    JE SCAN_DONE_2

    CALL SCAN_POSITION_FOR_COLOR
    CMP END_FLAG, 1
    JNE SCAN_FOR_POSITION

SCAN_DONE_2:
    ; Restaurar estado del archivo
    POP AX                    ; Restaurar END_FLAG desde AX
    MOV END_FLAG, AL
    POP AX                    ; Restaurar AX original
    POP BYTES_IN_BUFFER
    POP BUF_INDEX
    POP Y_CUR
    POP X_CUR
    
    MOV AL, [TEMP_COLOR]
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CHECK_SINGLE_COLOR_AT_POSITION ENDP

; ------------------ SCAN PARA COLOR ESPECÍFICO --------------------
SCAN_POSITION_FOR_COLOR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

NEXT_SCAN_BYTE:
    MOV BX, BUF_INDEX
    CMP BX, BYTES_IN_BUFFER
    JAE SCAN_DONE
    
    MOV SI, BX
    MOV AL, BUFFER[SI]
    INC BX
    MOV BUF_INDEX, BX

    MOV DL, AL
    CALL HEX_TO_NIBBLE
    JNC IS_SCAN_PIXEL

    MOV AL, DL
    CMP AL, '@'
    JE SCAN_END_LINE
    CMP AL, '%'
    JE SCAN_END_FILE
    CMP AL, 13
    JE NEXT_SCAN_BYTE
    CMP AL, 10
    JE NEXT_SCAN_BYTE
    CMP AL, ' '
    JE NEXT_SCAN_BYTE
    JMP NEXT_SCAN_BYTE

IS_SCAN_PIXEL:
    ; Verificar si estamos en la posición buscada
    MOV CX, X_CUR
    CMP CX, [TEMP_X]
    JNE SCAN_STEP_X
    
    MOV DX, Y_CUR
    CMP DX, [TEMP_Y]
    JNE SCAN_STEP_X
    
    ; ¡Encontramos la posición! Guardar el color
    MOV [TEMP_COLOR], AL
    MOV END_FLAG, 1
    JMP SCAN_DONE

SCAN_STEP_X:
    INC WORD PTR X_CUR
    JMP NEXT_SCAN_BYTE

SCAN_END_LINE:
    CALL SCAN_NEXT_ROW
    JMP NEXT_SCAN_BYTE

SCAN_END_FILE:
    MOV END_FLAG, 1

SCAN_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SCAN_POSITION_FOR_COLOR ENDP

SCAN_NEXT_ROW PROC
    INC WORD PTR Y_CUR
    MOV WORD PTR X_CUR, 0
    RET
SCAN_NEXT_ROW ENDP

; ------------------ VIDEO ----------------------
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
    ; Limpiar toda la pantalla (modo victoria necesita limpiar todo)
    MOV AX, 0600h
    MOV BH, 0
    MOV CX, 0000h       ; Fila 0, Columna 0
    MOV DX, 144Fh       ; Fila 24, Columna 79 (toda la pantalla)
    INT 10h
    RET
CLEAR_SCREEN ENDP

CLEAR_FULL_SCREEN PROC
    ; Limpiar TODA la pantalla (filas 0-24)
    MOV AX, 0600h
    MOV BH, 0
    MOV CX, 0000h       ; Fila 0, Columna 0
    MOV DX, 184Fh       ; Fila 24, Columna 79 (toda la pantalla)
    INT 10h
    RET
CLEAR_FULL_SCREEN ENDP

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
    MOV CX, 4096
    MOV AH, 3FH
    INT 21H
    JC READ_ERR
    MOV BYTES_IN_BUFFER, AX
    MOV WORD PTR BUF_INDEX, 0
    RET

READ_ERR:
    MOV BYTES_IN_BUFFER, 0
    MOV WORD PTR BUF_INDEX, 0
    RET
READ_CHUNK ENDP

REWIND_FILE PROC
    MOV AX, 4200h        ; Función Mover puntero de archivo
    MOV BX, FILE_HANDLE
    XOR CX, CX           ; Offset alto = 0
    XOR DX, DX           ; Offset bajo = 0  
    INT 21h
    RET
REWIND_FILE ENDP

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

; ------------------ CALCULAR PROGRESO --------------------
CALCULATE_PROGRESS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Calcular progreso basado en items recolectados (máximo 6 items = 100%)
    ; Cada item vale 16.67% ≈ 17% (redondeado)
    
    ; Sumar items recolectados (limitando a 2 por tipo)
    MOV AX, 0
    
    ; Monedas (máximo 2)
    MOV BX, COIN_COUNT
    CMP BX, 2
    JBE ADD_COINS
    MOV BX, 2
ADD_COINS:
    ADD AX, BX
    
    ; Espadas (máximo 2)
    MOV BX, SWORD_COUNT
    CMP BX, 2
    JBE ADD_SWORDS
    MOV BX, 2
ADD_SWORDS:
    ADD AX, BX
    
    ; Llaves (máximo 2)
    MOV BX, KEY_COUNT
    CMP BX, 2
    JBE ADD_KEYS
    MOV BX, 2
ADD_KEYS:
    ADD AX, BX
    
    ; AX ahora tiene el total de items válidos (0-6)
    
    ; Calcular porcentaje entero = (items * 100) / 6
    MOV BX, 100
    MUL BX              ; DX:AX = items * 100
    
    ; Dividir entre 6 para obtener porcentaje entero
    MOV BX, 6
    DIV BX              ; AX = porcentaje entero
    
    MOV PROGRESS_INT, AX
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CALCULATE_PROGRESS ENDP

; ------------------ RECOLECTAR OBJETOS --------------------
COLLECT_ITEM PROC
    PUSH BX
    PUSH CX
    MOV BX, VIEW_X
    MOV CX, VIEW_Y
    
    ; Guardar contadores antes
    MOV AX, COIN_COUNT
    MOV DX, SWORD_COUNT
    MOV SI, KEY_COUNT
    
    ;MONEDAS
    CALL CHECK_COIN1
    CALL CHECK_COIN2
    CALL CHECK_COIN3
    CALL CHECK_COIN4  
    CALL CHECK_COIN5
    
    ;ESPADAS
    CALL CHECK_SWORD1
    CALL CHECK_SWORD2
    CALL CHECK_SWORD3
    CALL CHECK_SWORD4
    CALL CHECK_SWORD5
    
    ;LLAVES
    CALL CHECK_KEY1
    CALL CHECK_KEY2
    CALL CHECK_KEY3
    CALL CHECK_KEY4
    CALL CHECK_KEY5
    
    ; Verificar si algún contador cambió
    CMP AX, COIN_COUNT
    JNE UPDATE_PROGRESS
    CMP DX, SWORD_COUNT
    JNE UPDATE_PROGRESS
    CMP SI, KEY_COUNT
    JNE UPDATE_PROGRESS
    JMP NO_UPDATE
    
UPDATE_PROGRESS:
    CALL CALCULATE_PROGRESS
    
NO_UPDATE:
    POP CX
    POP BX
    RET
COLLECT_ITEM ENDP

;------------------ CHECKS DE MONEDAS ------------------

CHECK_COIN1 PROC
    CMP BX, COIN1_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_COIN1_END
    CMP CX, COIN1_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_COIN1_END
    
    CMP COIN1_COLLECTED, 1
    JE CHECK_COIN1_END    ; Ya recolectada
    
    INC COIN_COUNT
    MOV COIN1_COLLECTED, 1
    
CHECK_COIN1_END:
    RET
CHECK_COIN1 ENDP

CHECK_COIN2 PROC
    CMP BX, COIN2_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_COIN2_END
    CMP CX, COIN2_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_COIN2_END
    
    CMP COIN2_COLLECTED, 1
    JE CHECK_COIN2_END    ; Ya recolectada
    
    INC COIN_COUNT
    MOV COIN2_COLLECTED, 1
    
CHECK_COIN2_END:
    RET
CHECK_COIN2 ENDP

CHECK_COIN3 PROC
    CMP BX, COIN3_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_COIN3_END
    CMP CX, COIN3_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_COIN3_END
    
    CMP COIN3_COLLECTED, 1
    JE CHECK_COIN3_END    ; Ya recolectada
    
    INC COIN_COUNT
    MOV COIN3_COLLECTED, 1
    
CHECK_COIN3_END:
    RET
CHECK_COIN3 ENDP

CHECK_COIN4 PROC
    CMP BX, COIN4_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_COIN4_END
    CMP CX, COIN4_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_COIN4_END
    
    CMP COIN4_COLLECTED, 1
    JE CHECK_COIN4_END    ; Ya recolectada
    
    INC COIN_COUNT
    MOV COIN4_COLLECTED, 1
    
CHECK_COIN4_END:
    RET
CHECK_COIN4 ENDP

CHECK_COIN5 PROC
    CMP BX, COIN5_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_COIN5_END
    CMP CX, COIN5_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_COIN5_END
    
    CMP COIN5_COLLECTED, 1
    JE CHECK_COIN5_END    ; Ya recolectada
    
    INC COIN_COUNT
    MOV COIN5_COLLECTED, 1
    
CHECK_COIN5_END:
    RET
CHECK_COIN5 ENDP

;------------------ CHECKS DE ESPADAS ------------------
CHECK_SWORD1 PROC
    CMP BX, SWORD1_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_SWORD1_END
    CMP CX, SWORD1_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_SWORD1_END
    
    CMP SWORD1_COLLECTED, 1
    JE CHECK_SWORD1_END    ; Ya recolectada
    
    INC SWORD_COUNT
    MOV SWORD1_COLLECTED, 1
    
CHECK_SWORD1_END:
    RET
CHECK_SWORD1 ENDP

CHECK_SWORD2 PROC
    CMP BX, SWORD2_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_SWORD2_END
    CMP CX, SWORD2_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_SWORD2_END
    
    CMP SWORD2_COLLECTED, 1
    JE CHECK_SWORD2_END    ; Ya recolectada
    
    INC SWORD_COUNT
    MOV SWORD2_COLLECTED, 1
    
CHECK_SWORD2_END:
    RET
CHECK_SWORD2 ENDP

CHECK_SWORD3 PROC
    CMP BX, SWORD3_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_SWORD3_END
    CMP CX, SWORD3_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_SWORD3_END
    
    CMP SWORD3_COLLECTED, 1
    JE CHECK_SWORD3_END    ; Ya recolectada
    
    INC SWORD_COUNT
    MOV SWORD3_COLLECTED, 1
    
CHECK_SWORD3_END:
    RET
CHECK_SWORD3 ENDP

CHECK_SWORD4 PROC
    CMP BX, SWORD4_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_SWORD4_END
    CMP CX, SWORD4_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_SWORD4_END
    
    CMP SWORD4_COLLECTED, 1
    JE CHECK_SWORD4_END    ; Ya recolectada
    
    INC SWORD_COUNT
    MOV SWORD4_COLLECTED, 1
    
CHECK_SWORD4_END:
    RET
CHECK_SWORD4 ENDP

CHECK_SWORD5 PROC
    CMP BX, SWORD5_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_SWORD5_END
    CMP CX, SWORD5_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_SWORD5_END
    
    CMP SWORD5_COLLECTED, 1
    JE CHECK_SWORD5_END    ; Ya recolectada
    
    INC SWORD_COUNT
    MOV SWORD5_COLLECTED, 1
    
CHECK_SWORD5_END:
    RET
CHECK_SWORD5 ENDP

;------------------ CHECKS DE LLAVES ------------------
CHECK_KEY1 PROC
    CMP BX, KEY1_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_KEY1_END
    CMP CX, KEY1_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_KEY1_END
    
    CMP KEY1_COLLECTED, 1
    JE CHECK_KEY1_END    ; Ya recolectada
    
    INC KEY_COUNT
    MOV KEY1_COLLECTED, 1
    
CHECK_KEY1_END:
    RET
CHECK_KEY1 ENDP

CHECK_KEY2 PROC
    CMP BX, KEY2_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_KEY2_END
    CMP CX, KEY2_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_KEY2_END
    
    CMP KEY2_COLLECTED, 1
    JE CHECK_KEY2_END    ; Ya recolectada
    
    INC KEY_COUNT
    MOV KEY2_COLLECTED, 1
    
CHECK_KEY2_END:
    RET
CHECK_KEY2 ENDP

CHECK_KEY3 PROC
    CMP BX, KEY3_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_KEY3_END
    CMP CX, KEY3_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_KEY3_END
    
    CMP KEY3_COLLECTED, 1
    JE CHECK_KEY3_END    ; Ya recolectada
    
    INC KEY_COUNT
    MOV KEY3_COLLECTED, 1
    
CHECK_KEY3_END:
    RET
CHECK_KEY3 ENDP

CHECK_KEY4 PROC
    CMP BX, KEY4_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_KEY4_END
    CMP CX, KEY4_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_KEY4_END
    
    CMP KEY4_COLLECTED, 1
    JE CHECK_KEY4_END    ; Ya recolectada
    
    INC KEY_COUNT
    MOV KEY4_COLLECTED, 1
    
CHECK_KEY4_END:
    RET
CHECK_KEY4 ENDP

CHECK_KEY5 PROC
    CMP BX, KEY5_POSX    ; BX ya tiene VIEW_X
    JNE CHECK_KEY5_END
    CMP CX, KEY5_POSY    ; CX ya tiene VIEW_Y
    JNE CHECK_KEY5_END
    
    CMP KEY5_COLLECTED, 1
    JE CHECK_KEY5_END    ; Ya recolectada
    
    INC KEY_COUNT
    MOV KEY5_COLLECTED, 1
    
CHECK_KEY5_END:
    RET
CHECK_KEY5 ENDP

; ------------------ VERIFICAR VICTORIA --------------------
CHECK_VICTORY_CONDITION PROC
    ; Verificar si todos los contadores son >= 2
    CMP COIN_COUNT, 2
    JL NO_VICTORY      ; Si COIN_COUNT < 2, no victoria
    CMP SWORD_COUNT, 2
    JL NO_VICTORY      ; Si SWORD_COUNT < 2, no victoria  
    CMP KEY_COUNT, 2
    JL NO_VICTORY      ; Si KEY_COUNT < 2, no victoria
    
    MOV AX, 1           ; Indicar victoria
    RET

NO_VICTORY:
    MOV AX, 0
    RET
CHECK_VICTORY_CONDITION ENDP

; ------------------ PANTALLA DE VICTORIA --------------------
SHOW_VICTORY PROC
    CALL CLEAR_FULL_SCREEN
    
    ; Posicionar cursor más arriba en la pantalla
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 8           ; Fila 8 (más arriba)
    MOV DL, 20          ; Columna 20 (centro horizontal)
    INT 10h
    
    ; Mostrar mensaje de victoria
    LEA SI, MSG_VICTORIA
    CALL PRINT_GRAPHIC_TEXT
    
    ; Mostrar estadísticas finales
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 10          ; Fila 10
    MOV DL, 20
    INT 10h
    
    LEA SI, MSG_ITEMS_COINS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, COIN_COUNT
    CALL PRINT_NUMBER
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 11          ; Fila 11
    MOV DL, 20
    INT 10h
    
    LEA SI, MSG_ITEMS_SWORDS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, SWORD_COUNT
    CALL PRINT_NUMBER
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 12          ; Fila 12
    MOV DL, 20
    INT 10h
    
    LEA SI, MSG_ITEMS_KEYS
    CALL PRINT_GRAPHIC_TEXT
    MOV AX, KEY_COUNT
    CALL PRINT_NUMBER
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 14          ; Fila 14
    MOV DL, 20
    INT 10h
    
    MOV SI, OFFSET MSG_CONTROLS
    CALL PRINT_GRAPHIC_TEXT
    
    RET
SHOW_VICTORY ENDP

END MAIN