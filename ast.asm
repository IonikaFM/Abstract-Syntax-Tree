section .data
    delim db " ", 0
    operators db "/*+", 0
    minus db "-", 0

section .bss
    root resd 1

section .text

extern check_atoi
extern print_tree_inorder
extern print_tree_preorder
extern evaluate_tree

extern malloc
extern strcpy
extern strlen
extern strtok
extern strchr
extern strcmp

global create_tree
global iocla_atoi

iocla_atoi:
    push ebp 
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + 8]                                          ; primeste sirul parametru
    movzx ebx, byte[eax]
    cmp ebx, 45                                                 ; verifica daca primul caracter este minus
    jne positive
    jmp negative


    ; daca numarul este pozitiv (nu are minus in fata) se va parcurge sirul incepand cu pozitia 0
    positive:
        mov ecx, 0                                              ; pozitia in sir 
        mov [ebp - 4], ecx                                      ; semnul sirului : 0 in caz pozitiv
        xor ebx, ebx                                            ; in ebx voi crea numarul in varianta int
        jmp create_number


    ; daca numarul este negativ (are minus in fata) se va parcurge sirul incepand cu pozitia 1 pentru a sari peste semn
    negative:
        mov ecx, 1  ; porneste sirul de la pozitia 1            ; pozitia in sir 
        mov [ebp - 4], ecx ; e 1 cand numarul e negativ         ; semnul sirului : 1 in caz negativ
        xor ebx, ebx                                            ; in ebx voi crea numarul in varianta int
        jmp create_number


    ; acest label reprezinta un while care, atata timp cat mai exista caractere in sir, va inmulti numarul deja creat
    ; (ebx) cu 10 si va adauga valoarea urmatorului caracter
    create_number:
        imul ebx, 10                                            ; number = number * 10;
        
        mov eax, [ebp + 8]                                      ; ia urmatorul caracter din sirul
        movzx edx, byte[eax + ecx]                              ; oferit ca parametru si scade din acesta valoarea
        sub edx, 48                                             ; 48 pentru a-l transforma in valoarea sa intreaga
        add ebx, edx                                            ; apoi il adauga la number (ebx)

        inc ecx                                                 ; incrementeaza pozitia in sir,
        push ecx                                                ; o salveaza pe stiva pentru
        push eax                                                ; a nu se pierde si apeleaza
        call strlen                                             ; functia strlen pentru sirul
        add esp, 4                                              ; oferit ca parametru

        pop ecx                                                 ; da pop de pe stiva contorului din sir
        cmp ecx, eax                                            ; si verifica daca mai exista caractere
        jl create_number                                        ; in caz pozitiv reia while-ul,
        jmp verify                                              ; altfel sare in verify

    ; se verifica daca numarul este negativ, comparand valoarea salvata din [ebp - 4] cu 1
    verify:
        mov eax, [ebp - 4]
        cmp eax, 1
        je was_negative
        jmp exit

   ; daca acea valoare este 1 inseamna ca numarul este negativ si il inmulteste pe number (ebx) cu -1
    was_negative:
        imul ebx, -1
        jmp exit

    ; se salveaza numarul in eax si se iese din functie
    exit:
        mov eax, ebx
        leave 
        ret

; am creat in plus o functie ajutatoare ce imi returneaza strtok(sir, " ")
get_number:
    push ebp 
    mov ebp, esp
    sub esp, 4

    mov eax, dword[ebp + 8]
    push eax
    call strlen
    add esp, 4

    inc eax                                                     ; am observat ca folosirea directa
    push eax                                                    ; a functiei strtok pe sirul
    call malloc                                                 ; parametru ii schimba acestuia
    add esp, 4                                                  ; din urma valoarea,

    mov edx, dword[ebp + 8]
    mov edi, eax                                                ; motiv pentru care
    push edx                                                    ; am ales sa ma folosesc de o copie
    push eax                                                    ; a acestui sir careia
    call strcpy                                                 ; ii aloc memorie si mai apoi
    add esp, 8                                                  ; apelez strtok pe ea

    push delim
    push edi
    call strtok
    add esp, 8

    leave
    ret 


create_tree:
    enter 0, 0
    sub esp, 4

    mov eax, dword[ebp + 8]                                     ; apeleaza functia
    push eax                                                    ; get_number pentru
    call get_number                                             ; a primi un singur numar
    add esp, 4                                                  ; din sir pe care
    mov edi, eax                                                ; il salveaza in edi

    mov eax, dword[ebp + 8]                                     ; calculeza strlen
    push eax                                                    ; de sir
    call strlen
    add esp, 4

    inc eax                                                     ; aloca memorie : (strlen(sir) + 1) * sizeof(char)
    push eax
    call malloc
    add esp, 4

    mov [ebp - 4], eax                                          ; in [ebp - 4] retin un sir auxiliar

    push edi
    call strlen                                                 ; retine in eax lungimea tokenului
    add esp, 4

    lea edx, [eax + 1]                                          ; intr-un sir auxiliar
    mov eax, dword[ebp + 8]                                     ; salvez doar partea
    add eax, edx                                                ; sirului ce nu a fost
    mov ecx, dword[ebp - 4]                                     ; parcursa inca cu ajutorul
    push eax                                                    ; functiei strcpy
    push ecx                                                    ; strcpy(aux, s + strlen(token) + 1);
    call strcpy
    add esp, 8

    mov ecx, dword[ebp - 4]                                     ; apelez din nou functia
    push ecx                                                    ; strcpy pentru a salva in
    mov eax, dword[ebp + 8]                                     ; sir acest sir auxiliar
    push eax                                                    ; calculat mai sus
    call strcpy                                                 ; strcpy(s, aux);
    add esp, 8

    cmp edi, 0                                                  ; verifica daca token ul e NULL
    je token_is_NULL

    push 12
    call malloc                                                 ; aloca memorie pentru nodul curent al arborelui
    add esp, 4

    mov ecx, eax                                                ; salveaza nodul tocmai alocat
    mov [ebp - 4], ecx                                          ; la adresa [ebp - 4]

    push 10
    call malloc                                                 ; aloca memorie pentru
    add esp, 4                                                  ; tree->data

    mov edx, [ebp - 4]
    mov [edx], eax
    push edi                                                    ; salveaza in tree->data tokenul (edi)
    push dword[edx]                                             ; strcpy(tree->data, token);
    call strcpy
    add esp, 8

    movzx eax, byte[edi]
    push eax                                                    ; compara primul caracter
    push operators                                              ; al sirului cu +, * si /
    call strchr                                                 ; folosind strchr
    add esp, 8
    
    cmp eax, 0                                                  ; daca rezultatul este diferit de 0
    jne recursive_tree                                          ; sare in label-ul recursive_tree

    push minus                                                  ; daca primul caracter nu a fost unul
    push edi                                                    ; din cei 3 operatori
    call strcmp                                                 ; compara tot token-ul cu minus
    add esp, 8                                                  ; folosind functia strcmp

    cmp eax, 0                                                  ; daca este diferit de 0 inseamna ca nu
    jne token_is_not_operator                                   ; este operator si sare in label-ul aferent,
    jmp recursive_tree                                          ; iar daca este egal cu 0 sare in recursive_tree

    recursive_tree:
        mov eax, dword[ebp + 8]
        push eax
        call create_tree                                        ; tree->left = create_tree(s);
        add esp, 4
        mov edx, [ebp - 4]
        mov [edx + 4], eax

        mov eax, dword[ebp + 8]
        push eax
        call create_tree                                        ; tree->right = create_tree(s);
        add esp, 4
        mov edx, [ebp - 4]
        mov [edx + 8], eax

        jmp return_node

    token_is_not_operator:
        mov eax, [ebp - 4]
        mov dword[eax + 4], 0                                   ; tree->left = tree->right = NULL;
        mov dword[eax + 8], 0
        
    return_node:
        mov eax, [ebp - 4]                                      ; return tree;
        jmp exit_tree

    token_is_NULL:
        mov eax, 0                                              ; daca token-ul a fost null returneaza 0

    exit_tree:
        leave
        ret