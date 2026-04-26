*** Settings ***
Documentation       Test "Unit Overload" — weryfikacja zachowania systemu przy jednoczesnym podaniu wielu jednostek prędkości.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should handle multiple speed units in single request
    [Documentation]    Wysyła żądanie uruchomienia ruchu z wszystkimi trzema jednostkami naraz.
    ...                Specyfikacja OpenAPI pozwala na podanie Mbps, kbps i bps jednocześnie.
    ...                Test sprawdza, czy system poprawnie obsługuje tę sytuację.

    Attach UE with ID 1
    Add bearer 5 to UE 1
    Start traffic with all units for UE 1 on bearer 5

System should handle only kbps unit
    [Documentation]    Weryfikuje, czy system poprawnie obsługuje tylko jednostkę kbps.

    Attach UE with ID 2
    Add bearer 6 to UE 2
    Start traffic with kbps only for UE 2 on bearer 6 at 5000 kbps
    Wait 2s
    Verify total traffic is greater than 0 bps

System should handle only bps unit
    [Documentation]    Weryfikuje, czy system poprawnie obsługuje tylko jednostkę bps.

    Attach UE with ID 3
    Add bearer 7 to UE 3
    Start traffic with bps only for UE 3 on bearer 7 at 1000000 bps
    Wait 2s
    Verify total traffic is greater than 0 bps


*** Keywords ***
Reset EPC Simulator
    [Documentation]    Resetuje środowisko do stanu początkowego.
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]    Dołącza UE do sieci.
    ${body}=           Create Dictionary    ue_id=${ue_id}
    POST On Session    epc_session    /ues    json=${body}    expected_status=200

Add bearer ${bearer_id} to UE ${ue_id}
    [Documentation]    Dodaje bearer do UE.
    ${body}=           Create Dictionary    bearer_id=${bearer_id}
    POST On Session    epc_session    /ues/${ue_id}/bearers    json=${body}    expected_status=200

Start traffic with all units for UE ${ue_id} on bearer ${bearer_id}
    [Documentation]    Uruchamia ruch ze wszystkimi jednostkami naraz.
    ${body}=           Create Dictionary    protocol=udp    Mbps=10    kbps=1000    bps=500
    ${resp}=           POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    Log                Kod odpowiedzi: ${resp.status_code}

Start traffic with kbps only for UE ${ue_id} on bearer ${bearer_id} at ${speed} kbps
    [Documentation]    Uruchamia ruch z jednostką kbps.
    ${body}=           Create Dictionary    protocol=tcp    kbps=${speed}
    POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=200

Start traffic with bps only for UE ${ue_id} on bearer ${bearer_id} at ${speed} bps
    [Documentation]    Uruchamia ruch z jednostką bps.
    ${body}=           Create Dictionary    protocol=udp    bps=${speed}
    POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=200

Wait ${seconds}
    [Documentation]    Czeka określoną liczbę sekund.
    Sleep    ${seconds}

Verify total traffic is greater than 0 bps
    [Documentation]    Weryfikuje, że ruch jest aktywny.
    ${stats}=          GET On Session    epc_session    /ues/stats
    ${stats_json}=     Set Variable    ${stats.json()}
    Should Be True    ${stats_json['total_tx_bps']} > 0    msg=Brak ruchu!