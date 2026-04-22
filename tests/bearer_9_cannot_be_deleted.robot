*** Settings ***
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://127.0.0.1:8000

*** Test Cases ***
Cannot Delete Default Bearer
    [Documentation]    Test weryfikujący brak możliwości usunięcia domyślnego bearera o ID 9
    
    Attach UE with ID 1
    Try to delete bearer 9 for UE 1
    Verify that an error occurred

*** Keywords ***
Reset EPC Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]    Wysyła żądanie dołączenia UE o zadanym ID do sieci
    ${body}=           Create Dictionary    ue_id=${ue_id}
    POST On Session    epc_session    /ues    json=${body}    expected_status=200

Try to delete bearer ${bearer_id} for UE ${ue_id}
    [Documentation]    Próbuje wykonać operację usunięcia i zapisuje odpowiedź do sprawdzenia
    ${resp}=             DELETE On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    Set Test Variable    ${last_response}    ${resp}

Verify that an error occurred
    [Documentation]    Sprawdza, czy ostatnia operacja zakończyła się błędem
    Should Be True     ${last_response.status_code} >= 400
    Log                Operacja zakończyła się błędem zgodnie z oczekiwaniami: ${last_response.status_code}
    