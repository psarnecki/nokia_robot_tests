*** Settings ***
Documentation       Suita testowa bezpieczeństwa weryfikująca luki typu BOLA.
Library             RequestsLibrary
Library             Collections
Library             BuiltIn

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000
${DEFAULT_BEARER}   9

*** Test Cases ***
System should prevent cross-bearer resource deletion
    [Documentation]    Weryfikuje, czy API prawidłowo waliduje przynależność Bearera do konkretnego UE przy usuwaniu.
    Attach UE with ID 2
    Add bearer 6 to UE 2
    Attach UE with ID 1
    Attempt to delete bearer 6 from UE 1 expecting failure

System should reject starting traffic on a bearer owned by another UE
    [Documentation]    Atakujący (UE 1) próbuje złośliwie uruchomić ruch na kanale ofiary (Bearer 6 należący do UE 2).
    ...                Weryfikuje, czy system zablokuje próbę "podrzucenia" ruchu do obcego rachunku.
    
    Attach UE with ID 2
    Add bearer 6 to UE 2
    Attach UE with ID 1
    Attempt to start traffic for UE 1 on bearer 6 expecting failure

System should prevent reading traffic stats for a bearer owned by another UE
    [Documentation]    Atakujący (UE 1) próbuje odczytać statystyki prywatnego kanału ofiary (UE 2).
    ...                Weryfikuje odporność na nieautoryzowany podgląd danych (Szpiegowanie).
    
    Attach UE with ID 2
    Add bearer 6 to UE 2
    Start DL traffic for UE 2 on bearer 6 via udp at 50 Mbps

    Attach UE with ID 1
    Attempt to read stats for UE 1 on bearer 6 expecting failure


*** Keywords ***
Reset EPC Simulator
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${body}=           Create Dictionary    ue_id=${numeric_id}
    ${resp}=           POST On Session    epc_session    /ues    json=${body}
    Status Should Be   200    ${resp}

Add bearer ${bearer_id_str} to UE ${ue_id}
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${body}=           Create Dictionary    bearer_id=${bearer_id}
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers    json=${body}
    Status Should Be   200    ${resp}

Start DL traffic for UE ${ue_id} on bearer ${bearer_id_str} via ${protocol} at ${speed_str} ${unit}
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${speed}=          Convert To Number     ${speed_str}
    ${body}=           Create Dictionary    protocol=${protocol}    ${unit}=${speed}
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}/traffic    json=${body}
    Status Should Be   200    ${resp}

Attempt to delete bearer ${bearer_id_str} from UE ${ue_id} expecting failure
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${resp}=           DELETE On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}    expected_status=any
    Should Be True     ${resp.status_code} >= 400    msg=BŁĄD. Serwer pozwolił na usunięcie obcego kanału! Status HTTP: ${resp.status_code} Wiadomość: ${resp.json()['detail']} 
    ${json_body}=      Set Variable    ${resp.json()}
    Log To Console     \n[ OK ] Zablokowano BOLA (Delete). Status: ${resp.status_code}. Wiadomość: ${json_body['detail']}

Attempt to start traffic for UE ${ue_id} on bearer ${bearer_id_str} expecting failure
    [Documentation]    Próbuje uruchomić ruch na nieswoim kanale i oczekuje błędu (np. 404/422).
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    
    ${body}=           Create Dictionary    protocol=tcp    Mbps=1.0
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    
    Should Be True     ${resp.status_code} >= 400    msg=BŁĄD KRYTYCZNY (Traffic Hijacking)! Serwer pozwolił UE ${ue_id} uruchomić ruch na obcym kanale ${bearer_id}. Status HTTP: ${resp.status_code} Wiadomość: ${resp.json()} 
    
    ${json_body}=      Set Variable    ${resp.json()}
    Log To Console     \n[ OK ] Zablokowano BOLA (Start Traffic). Status: ${resp.status_code}. Wiadomość: ${json_body['detail']}

Attempt to read stats for UE ${ue_id} on bearer ${bearer_id_str} expecting failure
    [Documentation]    Próbuje odczytać statystyki nieswojego kanału i oczekuje błędu (np. 404/403).
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    
    ${resp}=           GET On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}/traffic    expected_status=any
    
    Should Be True     ${resp.status_code} >= 400    msg=BŁĄD (Data Leakage)! Serwer udostępnił statystyki obcego kanału ${bearer_id} dla UE ${ue_id}. Status HTTP: ${resp.status_code} Wiadomość: ${resp.json()} 
    
    ${json_body}=      Set Variable    ${resp.json()}
    Log To Console     \n[ OK ] Zablokowano BOLA (Read Stats). Status: ${resp.status_code}. Wiadomość: ${json_body['detail']}