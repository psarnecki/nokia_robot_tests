*** Settings ***
Documentation       Testy weryfikujące zgodność implementacji API z dokumentacją.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://127.0.0.1:8000

*** Test Cases ***
Delete UE Traffic Without Bearer ID
    [Documentation]    Test weryfikujący dokumentację, która określa bearer_id jako opcjonalny.
    ...                Pominięcie opcjonalnego parametru powinno zakończyć się zakończeniem transferów dla wszystkich bearerów, a nie błędem.
    
    Attach UE with ID 1
    Try to stop all traffic for UE 1
    Verify that response is valid

Get UE Summary Stats Without Bearer ID And Unit
    [Documentation]    Test weryfikujący dokumentację, która określa bearer_id oraz unit jako opcjonalne.
    ...                Pominięcie opcjonalnych parametrów powinno zwrócić sumę transferów dla wszystkich bearerów, a nie błąd.

    Attach UE with ID 2
    Try to get summary stats for UE 2
    Verify that response is valid

Access Undocumented Stats Endpoint
    [Documentation]    Test potwierdzający istnienie nieudokumentowanej funkcjonalności /ues/stats.
    ...                Próba dostępu do tego endpointu powinna zakończyć się błędem, a nie sukcesem.
    
    Attach UE with ID 3
    Get system stats
    Verify that endpoint does not exist

*** Keywords ***
Reset EPC Simulator
    [Documentation]     Przywraca symulator do stanu początkowego.
    Create Session      epc_session    ${BASE_URL}
    POST On Session     epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]     Wysyła żądanie dołączenia UE o zadanym ID do sieci.
    ${body}=            Create Dictionary    ue_id=${ue_id}
    POST On Session     epc_session    /ues    json=${body}    expected_status=200

Try to stop all traffic for UE ${ue_id}
    [Documentation]     Próbuje zatrzymać cały ruch dla danego UE bez parametru bearer_id.
    ${resp}=            DELETE On Session    epc_session    /ues/${ue_id}/traffic    expected_status=any
    Set Test Variable   ${last_response}    ${resp}

Try to get summary stats for UE ${ue_id}
    [Documentation]     Próbuje pobrać sumaryczne statystyki dla UE bez parametrów bearer_id i unit.
    ${resp}=            GET On Session    epc_session    /ues/${ue_id}/traffic    expected_status=any
    Set Test Variable   ${last_response}    ${resp}

Get system stats
    [Documentation]     Wysyła zapytanie do endpointu /ues/stats w celu pobrania statystyk systemowych.
    ${resp}=            GET On Session    epc_session    /ues/stats    expected_status=any
    Set Test Variable   ${last_response}    ${resp}

Verify that endpoint does not exist
    [Documentation]     Weryfikuje, czy serwer poprawnie zwraca status błędu dla nieistniejących ścieżek.
    Should Be True      ${last_response.status_code} >= 404
    Log                 Endpoint nie istnieje.

Verify that response is valid
    [Documentation]     Sprawdza, czy kod statusu odpowiedzi jest pozytywny, co oznacza poprawne przetworzenie żądania przez API.
    Should Be True      ${last_response.status_code} < 400
    Log                 Endpoint działa poprawnie.
    