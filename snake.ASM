org 100h

push $1C
push TimerISR
push cs
call SetIntVector

mov        word [pOldISR], ax
mov        word [pOldISR + 2], dx

mov     ah, $0F
int     10h
mov     [bOldMode], al
mov     [bOldPage], bh

mov ax, $0013
int 10h

.GameLoop:
call ReadKey
cmp  ax,        word[exitKey]
je   ExitFromGame

push ax
call ChangeDirection
jmp  .GameLoop


ExitFromGame:
movzx ax, [bOldMode]
int 10h

mov ah, 05h
mov al, byte[bOldPage]
int 10h

push $1C
push word[pOldISR]
push word[pOldISR+2]
call SetIntVector

ret

TimerISR:
pusha
push        ds

push       cs
pop        ds


call ClearScreen
call DrawFood
call AdvanceSnake
call DrawSnake
call DrawBorders
call DidGameEnd

cmp  ax,        [GameIsEnd]
je   ExitFromGame

pop        ds
popa

iret


SetIntVector:
push bp
mov bp, sp

mov        bx, [bp+8]
shl        bx, 2

xor        ax, ax
mov        es, ax
mov        ax, [bp+6]
mov        dx, [bp+4]

pushf
cli
xchg       word [es:bx], ax
xchg       word [es:bx + 2], dx
popf

pop bp
ret 6


ClearScreen:
push bp
mov bp, sp

push       $A000
pop        es
xor        ax, ax
xor        di, di
mov        cx, 320 * 200
rep stosb

pop bp
ret


AdvanceSnake:
push bp
mov bp, sp

mov cx, [snakeLength]
dec cx

mov bx, snakeCoordinates

.Shift:
mov     di, word[bx+2]
mov     word[bx], di
add     bx, 2

loop .Shift

mov     bx, snakeCoordinates
mov     di, [snakeLength]
dec     di
shl     di, 1
mov     bx, word[bx+di]
add     bx, [snakeDirection]
mov     word[snakeCoordinates+di],   bx



mov     bx,   word[foodCoordinates]
mov     di,   word[snakeCoordinates+di]
cmp     bx,   di
je      .EatFood
jmp     .Exit

.EatFood:
mov     di,     [snakeLength]
shl     di,     1

mov     si,     [foodCoordinates]
mov     [snakeCoordinates+di],  si

inc     [snakeLength]
call    CreateNewFoodCoordinates
mov     [foodCoordinates],      ax


.Exit:


pop bp
ret

DrawSnake:
push    bp
mov     bp,sp

mov     ax,     $A000
mov     es,     ax
mov     cx,     word[snakeLength]
mov     bx,     snakeCoordinates
mov     al,     byte[snakeColor]
mov     di,     [bx]

.Start:
cmp     cx,     0
je      .Exit

mov     byte[es:di],    al

add     bx,     2

mov     di,     [bx]

dec     cx

jmp     .Start

.Exit:
pop     bp
ret


DrawBorders:
push    bp
mov     bp,sp

mov     ax,     $A000
mov     es,     ax
xor     di,     di
mov     cx,     320
mov     al,     [borderColor]
rep stosb


mov     di,     64000-320
mov     cx,     320
rep stosb

mov     cx,     200
mov     di,     0

.LeftBorder:
mov     [es:di],        al
add     di,             320

loop    .LeftBorder


mov     cx,     200
mov     di,     319

.RightBorder:
mov     [es:di],        al
add     di,             320

loop    .RightBorder

.Exit:
pop     bp
ret

DrawFood:
push    bp
mov     bp,sp

mov     ax, $A000
mov     es,  ax
mov     di, word[foodCoordinates]
mov     al, byte[foodColor]
mov     byte[es:di],        al


pop     bp
ret

CreateNewFoodCoordinates:
push    bp
mov     bp,sp

mov        ah, $2C
int        21h

movzx      ax, dl
rol        ax, 7
adc        ax, 23

mov        bx,  64000
div        bx

mov        di,  dx
movzx      si,  [borderColor]
cmp        di,  si
je         .ReNew

jmp        .Exit

.ReNew:
call  CreateNewFoodCoordinates

.Exit:
mov        ax,  dx

pop     bp
ret


ReadKey:
push bp
mov bp, sp

mov        ax, $0C08
int        21h
movzx      dx, al
test       al, al
jnz        @F
mov        ah, $08
int        21h
mov        dh, al

@@:
mov        ax, dx

pop bp
ret

ChangeDirection:
push bp
mov bp, sp
push ax
push di

mov ax, [bp+4]

cmp ax, [moveUp]
je  .KeyUp

cmp ax, [moveDown]
je  .KeyDown

cmp ax, [moveRight]
je  .KeyRight

cmp ax, [moveLeft]
je  .KeyLeft

jmp .Exit

.KeyLeft:

mov bx, word[snakeDirection]
cmp bx, word[snakeMoveRight]
je  .Exit

mov bx, word[snakeMoveLeft]
mov word[snakeDirection], bx
jmp .Exit

.KeyRight:

mov bx, word[snakeDirection]
cmp bx, word[snakeMoveLeft]
je  .Exit

mov bx, word[snakeMoveRight]
mov word[snakeDirection], bx
jmp .Exit

.KeyUp:

mov bx, word[snakeDirection]
cmp bx, word[snakeMoveDown]
je  .Exit

mov bx, word[snakeMoveUp]
mov word[snakeDirection], bx
jmp .Exit

.KeyDown:

mov bx, word[snakeDirection]
cmp bx, word[snakeMoveUp]
je  .Exit

mov bx, word[snakeMoveDown]
mov word[snakeDirection], bx

.Exit:

pop di
pop  ax
pop bp
ret 2

DidGameEnd:
push    bp
mov     bp,     sp

mov     di,     [snakeLength]
dec     di
shl     di,     1

mov     bx,     [snakeCoordinates+di]

mov     cx,     [snakeLength]
dec     cx
dec     cx

mov     di,     snakeCoordinates

.Start:
cmp     bx,     [di]
je      .EndGame

cmp     bx,     320
jbe     .UpperBorder
jmp    .CheckLowerBorder

.UpperBorder:
cmp     bx,     0
jae      .EndGame

.CheckLowerBorder:
cmp     bx,     64000
jbe    .LowerBorder
jmp    .Skip

.LowerBorder:
cmp     bx,     64000-320
jae     .EndGame

.CheckSideBorders:
mov     dx,     0
mov     ax,     bx
mov     si,     320
div     si
cmp     dx,     0
je      .EndGame

.Skip:
add     di,     2
loop    .Start

jmp     .NotEnd

.EndGame:
mov     ax,     [GameIsEnd]
jmp     .Exit

.NotEnd:
mov     ax,     [GameIsNotEnd]

.Exit:
pop     bp
ret


bOldMode        db      ?
bOldPage        db      ?
bOldTick        db      ?

pOldISR         dd      ?

moveLeft                dw      $4B00
moveRight               dw      $4D00
moveUp                  dw      $4800
moveDown                dw      $5000
exitKey                 dw      27
GameIsEnd               dw      1
GameIsNotEnd            dw      2

snakeDirection          dw      1
snakeMoveUp             dw      -320
snakeMoveDown           dw      320
snakeMoveLeft           dw      -1
snakeMoveRight          dw      1
foodColor               db      30h
foodCoordinates         dw      20000
borderColor             db      1h
snakeColor              db      70h
snakeLength             dw      12
snakeCoordinates        dw      32161, 32162, 32163, 32164, 32165, 32166, 32167, 32168, 32169, 32170, 32169, 32170




