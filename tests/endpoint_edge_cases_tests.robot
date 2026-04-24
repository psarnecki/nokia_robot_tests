*** Settings ***
Documentation       Testy weryfikujące odporność endpointu na brzegowe przypadki na pustym symulatorze
Library             RequestsLibrary
Library             Collections

Suite Setup         Create Session    epc_session    ${BASE_URL}
Suite Teardown      Delete All Sessions
Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://127.0.0.1:8000

*** Test Cases ***
Include Details On Empty Network — Should Not Crash
    [Documentation]    Sprawdza, czy GET /ues/stats?include_details=true nie zwraca 500,
    ...                gdy sieć jest pusta (brak podłączonych UE).

    Fetch stats with include details flag

    Verify that response is not a server error

Missing 404 Handler — Zapytanie o statystyki nieistniejącego UE
    [Documentation]    Sprawdza, czy GET /ues/stats?ue_id=99 na pustym symulatorze
    ...                zwraca udokumentowany kod (200 lub 422), a nie niespodziewane 404 lub 500.

    Fetch stats for nonexistent UE with id 99

    Verify that response code is documented

*** Keywords ***
Reset EPC Simulator
    [Documentation]    Przywraca symulator do stanu początkowego.
    POST On Session    epc_session    /reset

Fetch stats with include details flag
    [Documentation]    Wysyła GET /ues/stats z parametrem include_details=true i zapisuje odpowiedź.
    ${resp}=           GET On Session    epc_session    /ues/stats
    ...                params=include_details=true    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Fetch stats for nonexistent UE with id ${ue_id}
    [Documentation]    Wysyła GET /ues/stats z parametrem ue_id wskazującym na nieistniejące UE.
    ${resp}=           GET On Session    epc_session    /ues/stats
    ...                params=ue_id=${ue_id}    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Verify that response is not a server error
    [Documentation]    Weryfikuje, czy odpowiedź nie jest błędem serwera (5xx).
    Should Be True     ${last_response.status_code} < 500
    Log                Status: ${last_response.status_code} Body: ${last_response.text}    level=WARN

Verify that response code is documented
    [Documentation]    Weryfikuje, czy kod odpowiedzi należy do udokumentowanych (200 lub 422).
    ...                Wykrywa nieudokumentowane 404 lub błędy serwera 5xx.
    Should Be True     ${last_response.status_code} == 200 or ${last_response.status_code} == 422
    ...                msg=Nieudokumentowany kod odpowiedzi: ${last_response.status_code}
    Log                Status: ${last_response.status_code} Body: ${last_response.text}    level=WARN