*** Settings ***
Documentation       Test "Default Unit Issue" — weryfikacja poprawności jednostek prędkości.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should correctly display speed in kbps when kbps is used
    [Documentation]    Weryfikuje, czy system poprawnie wyświetla prędkość w kbps (kilobitach na sekundę).
    ...                Problem: system może wyświetlać tylko bity na sekundę zamiast kilobitów.

    Attach UE with ID 1
    Add bearer 5 to UE 1
    Start traffic with kbps for UE 1 on bearer 5 at 1000 kbps
    Wait 2s
    Verify traffic is approximately 1000000 bps

System should correctly convert Mbps to bps
    [Documentation]    Weryfikuje poprawność konwersji z Mbps na bps.

    Attach UE with ID 2
    Add bearer 6 to UE 2
    Start traffic with Mbps for UE 2 on bearer 6 at 5 Mbps
    Wait 2s
    Verify traffic is approximately 5000000 bps


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

Start traffic with kbps for UE ${ue_id} on bearer ${bearer_id} at ${speed} kbps
    [Documentation]    Uruchamia ruch z prędkością w kbps.
    ${body}=           Create Dictionary    protocol=udp    kbps=${speed}
    POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=200

Start traffic with Mbps for UE ${ue_id} on bearer ${bearer_id} at ${speed} Mbps
    [Documentation]    Uruchamia ruch z prędkością w Mbps.
    ${body}=           Create Dictionary    protocol=tcp    Mbps=${speed}
    POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=200

Wait ${seconds}
    [Documentation]    Czeka określoną liczbę sekund.
    Sleep    ${seconds}

Verify traffic is approximately ${expected} bps
    [Documentation]    Weryfikuje, że ruch jest zbliżony do oczekiwanej wartości.
    ${stats}=          GET On Session    epc_session    /ues/stats
    ${stats_json}=     Set Variable    ${stats.json()}
    ${lower}=         Evaluate    ${expected} * 0.9
    ${upper}=         Evaluate    ${expected} * 1.1
    Should Be True    ${stats_json['total_tx_bps']} >= ${lower} and ${stats_json['total_tx_bps']} <= ${upper}
    ...               msg=Ruch poza oczekiwanym zakresem!