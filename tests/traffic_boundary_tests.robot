*** Settings ***
Documentation       Testy weryfikujące ograniczenia prędkości transferu.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://127.0.0.1:8000

*** Test Cases ***
Traffic Over 100 Mbps Limit
    [Documentation]    Test weryfikujący, czy aplikacja poprawnie blokuje rozpoczęcie transferu przekraczającego limit górny 100 Mbps.
    
    Attach UE with ID 1
    Try to start traffic for UE 1 on bearer 9 at 180 Mbps
    Verify that request was rejected

Negative Transfer Speed Should Be Rejected
    [Documentation]    Test weryfikujący, czy aplikacja nie pozwala na przesyłanie prędkości ujemnych.
    
    Attach UE with ID 2
    Try to start traffic for UE 2 on bearer 9 at -40 Mbps
    Verify that request was rejected

*** Keywords ***
Reset EPC Simulator
    [Documentation]     Przywraca symulator do stanu początkowego.
    Create Session      epc_session    ${BASE_URL}
    POST On Session     epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]     Wysyła żądanie dołączenia UE o zadanym ID do sieci.
    ${body}=            Create Dictionary    ue_id=${ue_id}
    POST On Session     epc_session    /ues    json=${body}    expected_status=200

Try to start traffic for UE ${ue_id} on bearer ${bearer_id} at ${speed} Mbps
    [Documentation]     Uruchamia ruch i zapisuje wynik w zmiennej testowej.
    ${body}=            Create Dictionary    protocol=tcp    Mbps=${speed}
    ${resp}=            POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    Set Test Variable   ${last_response}    ${resp}

Verify that request was rejected
    [Documentation]     Sprawdza czy otrzymany kod statusu odpowiedzi wskazuje na błąd walidacji lub logiki.
    Should Be True      ${last_response.status_code} >= 400
    Log                 Operacja zakończyła się błędem: ${last_response.status_code}
    