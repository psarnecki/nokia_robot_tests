*** Settings ***
Documentation       Test "Missing Aggregate Traffic Stop Endpoint" — weryfikacja endpointu zatrzymania sumarycznego ruchu.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should support aggregate traffic stop for all UEs
    [Documentation]    Testuje endpoint DELETE /ues/traffic do zatrzymania ruchu na wszystkich UE jednocześnie.
    ...                Brak tego endpointu uniemożliwia zatrzymanie wszystkich sesji ruchu jednym żądaniem.

    Attach UE with ID 1
    Attach UE with ID 2
    Add bearer 5 to UE 1
    Add bearer 5 to UE 2
    Start traffic for UE 1 on bearer 5 at 10 Mbps
    Start traffic for UE 2 on bearer 5 at 10 Mbps
    Wait 2s
    Verify traffic is active
    Stop all traffic
    Verify traffic stopped


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

Start traffic for UE ${ue_id} on bearer ${bearer_id} at ${speed} Mbps
    [Documentation]    Uruchamia ruch dla konkretnego UE i bearera.
    ${body}=           Create Dictionary    protocol=udp    Mbps=${speed}
    POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=200

Wait ${seconds}
    [Documentation]    Czeka określoną liczbę sekund.
    Sleep    ${seconds}

Verify traffic is active
    [Documentation]    Weryfikuje, że ruch jest aktywny.
    ${stats}=          GET On Session    epc_session    /ues/stats
    ${stats_json}=     Set Variable    ${stats.json()}
    Should Be True    ${stats_json['total_tx_bps']} > 0    msg=Brak ruchu!

Stop all traffic
    [Documentation]    Zatrzymuje ruch sumaryczny na wszystkich UE.
    ${resp}=           DELETE On Session    epc_session    /ues/traffic    expected_status=any
    Set Test Variable  ${stop_response}    ${resp}

Verify traffic stopped
    [Documentation]    Weryfikuje, że ruch został zatrzymany.
    ${stats}=          GET On Session    epc_session    /ues/stats
    ${stats_json}=     Set Variable    ${stats.json()}
    Should Be Equal As Integers    ${stats_json['total_tx_bps']}    0    msg=Ruch nadal trwa!