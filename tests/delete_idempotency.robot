*** Settings ***
Documentation       Test Idempotentności Usunięcia — DELETE powinien być idempotentny
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should handle repeated delete requests gracefully
    [Documentation]    Weryfikuje, że wielokrotne usunięcie tego samego zasobu nie powoduje błędu 500.
    ...                Pierwsze DELETE usuwa UE. Drugie DELETE powinno zwrócić 404 lub 200.

    Attach UE with ID 10
    Delete UE with ID 10
    Wait 1s
    Delete UE with ID 10 again
    Verify second delete did not return server error


*** Keywords ***
Reset EPC Simulator
    [Documentation]    Resetuje środowisko do stanu początkowego.
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]    Dołącza UE do sieci.
    ${body}=           Create Dictionary    ue_id=${ue_id}
    POST On Session    epc_session    /ues    json=${body}    expected_status=200

Delete UE with ID ${ue_id}
    [Documentation]    Usuwa UE z sieci.
    DELETE On Session    epc_session    /ues/${ue_id}    expected_status=200

Delete UE with ID ${ue_id} again
    [Documentation]    Ponawia próbę usunięcia UE.
    ${resp}=           DELETE On Session    epc_session    /ues/${ue_id}    expected_status=any
    Set Test Variable  ${second_delete_response}    ${resp}

Verify second delete did not return server error
    [Documentation]    Weryfikuje, że drugie żądanie DELETE nie zwróciło błędu 500.
    Should Be True    ${second_delete_response.status_code} != 500
    ...               msg=Błąd! Drugie żądanie usunięcia zwróciło błąd serwera 500!

Wait ${seconds}
    [Documentation]    Czeka określoną liczbę sekund.
    Sleep    ${seconds}