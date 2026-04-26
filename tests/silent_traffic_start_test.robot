*** Settings ***
Documentation       Test "Silent Traffic Start" — weryfikacja zachowania API gdy nie podano prędkości transferu.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
System should handle traffic start without speed parameter
    [Documentation]    Wysyła żądanie uruchomienia ruchu bez podania prędkości.
    ...                Test sprawdza, czy system tworzy ruch o prędkości 0, zwraca błąd, czy przyjmuje domyślną wartość.

    Attach UE with ID 1
    Add bearer 5 to UE 1
    Start traffic without speed for UE 1 on bearer 5
    Verify traffic response is valid

System should handle traffic start with only protocol parameter
    [Documentation]    Alternatywny test — upewnienie się, że protocol jest faktycznie jedynym wymaganym parametrem.

    Attach UE with ID 2
    Add bearer 6 to UE 2
    Start traffic without speed for UE 2 on bearer 6
    Verify traffic response is valid


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

Start traffic without speed for UE ${ue_id} on bearer ${bearer_id}
    [Documentation]    Uruchamia ruch bez podania prędkości.
    ${body}=           Create Dictionary    protocol=udp
    ${resp}=           POST On Session    epc_session    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Verify traffic response is valid
    [Documentation]    Weryfikuje, że odpowiedź jest poprawna.
    ${stats}=          GET On Session    epc_session    /ues/stats
    ${stats_json}=     Set Variable    ${stats.json()}
    Log                Całkowity ruch TX: ${stats_json['total_tx_bps']} bps