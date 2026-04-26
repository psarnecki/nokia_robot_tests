*** Settings ***
Documentation       Boundary Value Analysis — walidacja granic wejściowych API
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should reject UE ID above maximum limit
    [Documentation]    Sprawdza, czy system poprawnie odmawia dołączenia UE z ID większym niż 100.
    ...                ID urządzenia musi być w zakresie 0-100.

    Try to attach UE with ID 101
    Verify request was rejected with validation error

System should reject Bearer ID above maximum limit
    [Documentation]    Sprawdza, czy system poprawnie odmawia dodania bearera z ID większym niż 9.
    ...                Numer bearera musi być w zakresie 1-9.

    Attach UE with ID 1
    Try to add bearer with ID 10
    Verify request was rejected with validation error

System should reject invalid protocol type
    [Documentation]    Sprawdza, czy system poprawnie odmawia uruchomienia ruchu z protokołem HTTP.
    ...                Dozwolone protokoły to tylko TCP i UDP.

    Attach UE with ID 1
    Try to start traffic with http protocol
    Verify request was rejected with validation error


*** Keywords ***
Reset EPC Simulator
    [Documentation]    Resetuje środowisko do stanu początkowego.
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]    Dołącza UE do sieci.
    ${body}=           Create Dictionary    ue_id=${ue_id}
    POST On Session    epc_session    /ues    json=${body}    expected_status=200

Try to attach UE with ID ${ue_id}
    [Documentation]    Próbuje dołączyć UE z podanym ID.
    ${body}=           Create Dictionary    ue_id=${ue_id}
    ${resp}=           POST On Session    epc_session    /ues    json=${body}    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Try to add bearer with ID ${bearer_id}
    [Documentation]    Próbuje dodać bearer z podanym ID.
    ${body}=           Create Dictionary    bearer_id=${bearer_id}
    ${resp}=           POST On Session    epc_session    /ues/1/bearers    json=${body}    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Try to start traffic with http protocol
    [Documentation]    Próbuje uruchomić ruch z protokołem HTTP.
    ${body}=           Create Dictionary    protocol=http    Mbps=10
    ${resp}=           POST On Session    epc_session    /ues/1/bearers/9/traffic    json=${body}    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Verify request was rejected with validation error
    [Documentation]    Weryfikuje, że żądanie zostało odrzucene z błędem walidacji 422.
    Should Be Equal As Integers    ${last_response.status_code}    422
