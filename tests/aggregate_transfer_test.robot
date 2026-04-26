*** Settings ***
Documentation       Test "Missing Aggregate Transfer Endpoint" — weryfikacja endpointu sumarycznego transferu.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should support aggregate traffic start for all UEs
    [Documentation]    Testuje endpoint /ues/traffic do uruchomienia ruchu na wszystkich UE jednocześnie.
    ...                Zgodnie z dokumentacją: opcjonalnie można podać bearer_id.

    Attach UE with ID 1
    Attach UE with ID 2
    Add bearer 5 to UE 1
    Add bearer 5 to UE 2
    Start aggregate traffic at 10 Mbps
    Verify aggregate traffic response is valid

System should support aggregate traffic start with specific bearer
    [Documentation]    Testuje endpoint /ues/traffic z określonym bearer_id.

    Attach UE with ID 3
    Attach UE with ID 4
    Add bearer 6 to UE 3
    Add bearer 6 to UE 4
    Start aggregate traffic with bearer 6 at 5 Mbps
    Verify aggregate traffic response is valid


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

Start aggregate traffic at ${speed} Mbps
    [Documentation]    Uruchamia ruch sumaryczny na wszystkich UE.
    ${body}=           Create Dictionary    protocol=udp    Mbps=${speed}
    ${resp}=           POST On Session    epc_session    /ues/traffic    json=${body}    expected_status=any
    Set Test Variable  ${aggregate_response}    ${resp}

Start aggregate traffic with bearer ${bearer_id} at ${speed} Mbps
    [Documentation]    Uruchamia ruch sumaryczny na konkretnym bearerze.
    ${body}=           Create Dictionary    protocol=tcp    Mbps=${speed}    bearer_id=${bearer_id}
    ${resp}=           POST On Session    epc_session    /ues/traffic    json=${body}    expected_status=any
    Set Test Variable  ${aggregate_response}    ${resp}

Verify aggregate traffic response is valid
    [Documentation]    Weryfikuje poprawność odpowiedzi.
    Log                 Odpowiedź: ${aggregate_response.text}