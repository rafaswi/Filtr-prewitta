;Filtr Prewitta z histogramem
;Rafa� �widerski
;Rok akademicki 2020/2021
;wersja 1.0
;historia:
; wersja 0.1 : Szkielet zagnie�d�onych p�tli oraz �ci�ganie zmiennej ze stosu.
; wersja 0.2 : Wyliczanie adresu pikseli w inner_X_sum_loop + ify dla pikseli na rogach obrazka.
; wersja 0.25: Tworzenie wektora z element�w tablicy kernel.
; wersja 0.3 : Mno�enie wektor�w z warto�ciami piksela z wektorem element�w tablicy kernel oraz dodawanie ich do wektora wynikowego (xmm2).
; wersja 0.4 : Naprawienie wektora element�w tablic kernel i kernely.
; wersja 0.5 : Od teraz elementy w rejestrach xmm przechowywane s� jako float(poprzednio int), 
; optymalizacja pami�ciowa zmiennych (poprzednio np. tablica kernel by�a typu SDWORD, od teraz jest typu SBYTE.
; wersja 0.55: Obliczanie poprawnego wyniku dzia�ania algorytmu, kt�ry umieszczany jest w rejestrze xmm6 (wektor 3 elementowy z warto�ciami RGB).
; wersja 0.7 : Wyci�ganie warto�ci nowego piksela z rejestru xmm oraz implementacji if�w sprawdzaj�cych zakres nowych warto�ci RGB.
; wersja 0.9 : Procedura poprawnie dzia�a na jednym w�tku, ale wysypuje si� przy pr�bie odpalenia na wi�cej ni� jednym.
; wersja 1.0 : Procedura poprawnie dzia�a na wielu w�tkach.
.data
kernel SBYTE -1,0,1
       SBYTE -1,0,1
       SBYTE -1,0,1
kernely SBYTE 1,1,1
       SBYTE 0,0,0
       SBYTE -1,-1,-1
.code

;Procedura stosuje na podanej tablicy piksel�w bitmapy filtr Prewitta.
;Nie sprawdza parametr�w wej�ciowych.
;@param char*: Wska�nik na tablice pikseli, tablica ta nie mo�e zawiera� paddingu.
;@param char*: Wska�nik na wynikow� tablice pikseli : char* , buffor do zapisu wyniku. W wyniku dzia�ania procedury warto�ci w tej tablicy ulegaj� zmianie.
; Wielko�� tablicy wynikowej musi by� taka sama jak wielko�� tablicy pikseli.
;@param int  : Szeroko�� bitmapy: int, szeroko�� bitmapy w pikselach. UWAGA: Do procedury nale�y poda� szeroko�� bitmapy pomniejszon� o 2 piksele.
;@param int  : Kolumna startowa: int, kolumna bitmapy od kt�rej procedura zacznie. W przypadku dzia�ania na 1 w�tku poda� 0,
;w przypadku dzia�ania na 2 poda� po�owe wysoko�ci bitmapy w pikselach itd.
;@param int  : Kolumna ko�cowa: int, kolumna bitmapy na kt�rej algorytm sko�czy. W przypadku dzia�ania na 1 w�tku poda� wysoko�� bitmapy w pikselach,
;w przypadku dzia�ania na 2 poda� po�owe wysoko�ci bitmapy w pikselach itd. Ostatni w�tek (lub pierwszy je�li procedura ma dzia�a� tylko na jednym w�tku) musi mie� przekazany
;ten parametr pomniejszony o 2.
;@warning modyfikowane rejestry: RCX,RBX,RBP,RSI,R8,R9,R10,R11,R12,R13,R14,R15,XMM0,XMM1,XMM2,XMM3,XMM4,XMM5,XMM6
prewittFilter proc
; rcx - pointer to inputArray
; rdx - pointer to outputArray, przenoszony do r14 na pocz�tku procedury
; rbp licznik wewn�trznej p�tli
; r8 - bitmap width
; r9 - start height / i
; r10 - stop height / j
; xmm2 - wektor sumXb,sumXg,sumXr
; xmm4 - wektor sumYb, sumYg,sumYr
; xmm6 - wektor SUMb,SUMg,SUMr
    push rbp ; zapisywanie adres�w rejestr�w RBP,RBX, RDI,RSP, w celu zachowania sp�jno�ci pami�ci po wykonaniu procedury
    push rbx
    push rdi
    push rsp
    mov r15,[rsp+72] ; stop height do r15, 8* number_saved_reg(w tym przypadku 8*9)
    mov r14,rcx ;r14 - pointer to inputArray
    mov rbx,rdx ; rbx - pointer to outputArray  
    mov rdi,r9 ; start height do rdi

  ;zerowanie rejestr�w-------------------------------------------------------
    xor rcx,rcx
    xor r11,r11 
    xor r12,r12
    xor r13,r13
   ;-------------------------------------------------------------------------
    mov ecx, edi ; Ustawianie licznika p�tlie (rejestru ecx). W edi znajduje si� zmienna start_height
    push r15
    outerLoop:
    pop r15
    cmp ecx,r15d ; Sprawdzanie warunka ko�cz�cego p�tle.
    push r15
    je done

    mov ebp,0
    innerLoop:
    cmp ecx,0 ; if(y==0) sumB,sumG,sumR = 0
    je skipX
    
    pop r15
    mov eax,r15d
    inc eax
    push r15
    cmp ecx,eax  ; if(y>=stop_height-1) sumB,sumG,sumR = 0 => skok do etykiety skipX
    jge skipX

    cmp ebp,0 ;if(x==0) sumB,sumG,sumR = 0 => skok do etykiety skipX
    je skipX

    mov eax, r8d
    dec eax
    cmp ebp,eax ; if(x>=width-1) sumB,sumG,sumR = 0 => skok do etykiety skipX
    jge skipX

  
    mov r9d,0
    outer_X_sum_loop:
    mov r10d,0

    inner_X_sum_loop:
    ; wyliczanie adresu piksela B [3 * (X + I + (Y + J) * width)]------------
    xor rax, rax
    xor r15,r15
    add eax,ecx
    add r15d,r10d
    dec r15d
    add eax,r15d
    mov r15d,r8d
    add r15d,2
    mul r15d
    add eax,ebp
    xor r15,r15
    mov r15d,r9d
    dec r15d
    add eax,r15d
    xor r15,r15
    mov r15b,3
    movzx r15d,r15b
    mul r15d
    mov r11b, [r14+rax] ;przeniesienie warto�ci piksela B do rejestru r11b , inputArray[3 * (X + I + (Y + J) * width)]
    ;-----------------------------------------------------------------------
    inc rax  ; inkrementacja rax, aby dosta� adres piksela G 
    mov r12b,[r14+rax] ; przeniesienie warto�ci piksela B do rejestru r12b , inputArray[3 * (X + I + (Y + J) * width) + 1]
    ;-----------------------------------------------------------------------
    inc rax ; inkrementacja rax po raz drugi, aby dosta� adres piksela R
    mov r13b,[r14+rax] ; przeniesienie warto�ci piksela R do rejestru r13b , inputArray[3 * (X + I + (Y + J) * width) + 2]
    ;-----------------------------------------------------------------------
    ; Umieszczanie warto�ci pikseli B, G i R w rejestrze xmm0---------------
    movzx r11d,r11b
    cvtsi2ss xmm0,r11d
    pshufd xmm0,xmm0,207 ; 207 - maska bitowa 11001111b
    movzx r12d,r12b
    cvtsi2ss xmm0,r12d
    pshufd xmm0,xmm0,227 ; 227 - maska bitowa 11100011b
    movzx r13d,r13b
    cvtsi2ss xmm0,r13d
    movaps xmm3,xmm0 ; tworzenie kopii wektora xmm0, aby wykorzysta� j� do liczenia sum dla Y
    ;-----------------------------------------------------------------------
    ; Tworzenie wektora element�w z tablicy kernel--------------------------
    lea rsi,[kernel] ;pobranie adresu tablicy kernel do rsi
    xor r15,r15
    mov eax,r9d
    mov r15b,3
    movzx r15d,r15b
    mul r15d
    add eax,r10d
    xor r15,r15
    mov r15b,[rsi+rax]
    movsx r15d,r15b
    cvtsi2ss xmm1,r15d
    pshufd xmm1,xmm1,192 ; 192 - maska bitowa 11000000b
    ;-----------------------------------------------------------------------
    ; Mno�enie inputArray[3 * (X + I + (Y + J) * width)] * kernel[I + 1][J + 1], czyli elementy wektora z rejestru xmm0 * elementy xmm1,
    ; a potem dodanie dodanie wyniku operacji do wektora z rejestru xmm2
    mulps xmm0,xmm1
    addps xmm2,xmm0
    ;-----------------------------------------------------------------------
    ; w rezultacie efekt mo�na opisa� za pomoc� kodu c++ nast�puj�co:
    ;sumXb += inputArray[3 * (X + I + (Y + J) * width)] * kernel[I + 1][J + 1];
	;sumXg += inputArray[3 * (X + I + (Y + J) * width) + 1] * kernel[I + 1][J + 1];
	;sumXr += inputArray[3 * (X + I + (Y + J) * width) + 2] * kernel[I + 1][J + 1];
    ;-----------------------------------------------------------------------
    ; Tworzenie wektora element�w z tablicy kernely-------------------------
    lea rsi,[kernely] ;pobranie adresu tablicy kernely do rsi
    xor r15,r15
    mov eax,r9d
    mov r15b,3
    movzx r15d,r15b
    mul r15d
    add eax,r10d
    xor r15,r15
    mov r15b,[rsi+rax]
    movsx r15d,r15b
    cvtsi2ss xmm1,r15d
    pshufd xmm1,xmm1,192 ; 192 - maska bitowa 11000000b
    ;-----------------------------------------------------------------------
    ; Mno�enie inputArray[3 * (X + I + (Y + J) * width)] * kernely[I + 1][J + 1], czyli elementy wektora z rejestru xmm3 * elementy xmm1,
    ; a potem dodanie dodanie wyniku operacji do wektora z rejestru xmm4
    mulps xmm3,xmm1
    addps xmm4,xmm3
    ;-----------------------------------------------------------------------
    ; w rezultacie efekt mo�na opisa� za pomoc� kodu c++ nast�puj�co:
    ;sumYb += inputArray[3 * (X + I + (Y + J) * width)] * kernely[I + 1][J + 1];
	;sumYg += inputArray[3 * (X + I + (Y + J) * width) + 1] * kernely[I + 1][J + 1];
	;sumYr += inputArray[3 * (X + I + (Y + J) * width) + 2] * kernely[I + 1][J + 1];
    ;-----------------------------------------------------------------------

    cmp r10d,2
    jge inner_X_sum_done
    inc r10d
    jmp inner_X_sum_loop

    inner_X_sum_done:
    cmp r9d,2
    jge outer_X_sum_done
    inc r9d
    jmp outer_X_sum_loop
    
    outer_X_sum_done:
    ; Obliczanie wyniku ko�cowego-------------------------------------------
    mulps xmm2,xmm2 ; podnoszenie element�w wektora do pot�gi 2
    mulps xmm4,xmm4 ; podnoszenie element�w wektora do pot�gi 2
    movaps xmm6,xmm2 ; przeniesienie jednego z wektor�w do rejestru xmm6(rejestr wynikowy)
    addps xmm6,xmm4
    sqrtps xmm6,xmm6
    ;-----------------------------------------------------------------------
    ; W rezultacie w rejestrze xmm6 znajduje si� wektor element�w SUMb,SUMg i SUMr. Dzia�ania powy�ej mo�na opisa� za pomoc� kodu c++:
    ;SUMb = sqrt((sumXb * sumXb) + (sumYb * sumYb));
	;SUMg = sqrt((sumXg * sumXg) + (sumYg * sumYg));
	;SUMr = sqrt((sumXr * sumXr) + (sumYr * sumYr));
    ;-----------------------------------------------------------------------
    ; Wyci�ganie warto�ci nowych pikseli z rejestru xmm6. Warto�� R l�duje w r11d, warto�� G w r12d, a B w r13d
    movaps xmm5,xmm6
    cvtss2si r11d,xmm5
    pshufd xmm5,xmm5,237 ; sum g od teraz na 1 pozycji
    cvtss2si r12d,xmm5
    pshufd xmm5,xmm5,254 ; sum b na 1 pozycji
    cvtss2si r13d,xmm5
    ;-----------------------------------------------------------------------
    ; Sprawdzanie czy nowa warto�� pikseli mie�ci si� w granicy 0-255. Dodatkowo jak nowa warto�� jest <20 to ustawianie jej na 0.
    ; Ca�y poni�szy kod mo�na w c++ zapisa� jako:
    ;if (SUMb > 255) SUMb = 255;
	;if (SUMg > 255) SUMg = 255;
	;if (SUMr > 255) SUMr = 255;
	;if (SUMb < 20) SUMb = 0;
	;if (SUMg < 20) SUMg = 0;
	;if (SUMr < 20) SUMr = 0;
    cmp r13d,255 ; if (SUMb > 255) SUMb=255
    jg set_SUMb255

    if_SUMgGreaterThan255:
    cmp r12d,255 ; if (SUMb > 255) SUMg=255
    jg set_SUMg255

    if_SUMrGreaterThan255:
    cmp r11d,255 ;if (SUMr > 255) SUMr = 255;
    jg set_SUMr255

    if_SUMbLesserThan20:
    cmp r13d,20 ;if (SUMb < 20) SUMb = 0;
    jl set_SUMb0

    if_SUMgLesserThan20:
    cmp r12d,20 ;if (SUMg < 20) SUMg = 0;
    jl set_SUMg0

    if_SUMrLesserThan20:
    cmp r11d,20 ;if (SUMr < 20) SUMr = 0;
    jl set_SUMr0

    jmp noSUM_set ; Je�eli warto�ci by�y w granicach skok do noSUM_set

    ; Etykiety set_SUM ustawiaj� warto�ci RGB piksela na 0 lub 255
    set_SUMb255:
    mov r13d,255
    jmp if_SUMgGreaterThan255

    set_SUMg255:
    mov r12d,255
    jmp if_SUMrGreaterThan255

    set_SUMr255:
    mov r11d,255
    jmp if_SUMbLesserThan20

    set_SUMb0:
    mov r13d,0
    jmp if_SUMgLesserThan20

    set_SUMg0:
    mov r12d,0
    jmp if_SUMrLesserThan20

    set_SUMr0:
    mov r11d,0
    ;-----------------------------------------------------------------------
    noSUM_set:
    xorpd xmm2,xmm2
    xorpd xmm4,xmm4
    xorpd xmm6,xmm6
    jmp valuesNot0
    skipX:
    ; Ustawianie sk�adowych RGB piksela na 0.
    mov r11b,0
    mov r12b,0
    mov r13b,0
    ;----------------------------------------------------------------------
    valuesNot0:
    ; Wyliczanie adresu nowych warto�ci piksela, outputArray[3 * (X + Y * width)]
    xor rax,rax
    add eax,ecx
    mov r15d,r8d
    add r15d,2
    mul r15d
    add eax,ebp
    xor r15,r15
    mov r15b,3
    movzx r15d,r15b
    mul r15d
    xor r15,r15
    ;----------------------------------------------------------------------
    ; Umieszczanie nowych warto�ci RGB w tablicy wynikowej outputArray
    mov [rbx+rax],r13b
    inc rax
    mov [rbx+rax],r12b
    inc rax
    mov [rbx+rax],r11b
    ;----------------------------------------------------------------------
    ; Zerowanie rejestr�w
    xor r13,r13
    xor r12,r12
    xor r11,r11
    ;----------------------------------------------------------------------
    ; W rezultacie powy�szy kod mo�na pokaza� za pomoc� c++:
    ; outputArray[3 * (X + Y * width)] = SUMb;
	; outputArray[3 * (X + Y * width) + 1] = SUMg;
	; outputArray[3 * (X + Y * width) + 2] = SUMr;
    ;----------------------------------------------------------------------
    cmp ebp,r8d
    je innerLoopDone
    inc ebp
    jmp innerLoop

   innerLoopDone:
    inc ecx
    jmp outerLoop

    done:
    pop r15
    pop rsp ; �ci�ganie warto�ci rejestr�w ze stosu
    pop rdi
    pop rbx
    pop rbp
    mov eax,0 ; procedura zwraca 0
	ret
prewittFilter endp
end