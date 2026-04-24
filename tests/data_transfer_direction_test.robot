*** Settings ***
Documentation       Testy weryfikujące kierunkowość transferu danych — tylko DL powinien być aktywny.
Library             RequestsLibrary
Library             Collections

Suite Setup         Create Session    epc_session    ${BASE_URL}
Suite Teardown      Delete All Sessions
Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://127.0.0.1:8000

*** Test Cases ***
UL Traffic Should Be Zero After DL Session Start
    [Documentation]    Zgodnie ze specyfikacją transfer działa tylko w kierunku DL. Test wykrywa błąd, jeśli symulator generuje ruch w obu kierunkach.
    ...                Po uruchomieniu ruchu rx_bps powinno wynosić 0.

    Attach UE with ID 1
    Start DL traffic for UE 1 on bearer 9 via udp at 50 Mbps
    Fetch traffic stats for UE 1 on bearer 9
    Verify that UL traffic is exactly 0 bps

*** Keywords ***
Reset EPC Simulator
    [Documentation]    Przywraca symulator do stanu początkowego.
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]    Wysyła żądanie dołączenia UE o zadanym ID do sieci.
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${body}=           Create Dictionary    ue_id=${numeric_id}
    POST On Session    epc_session    /ues    json=${body}    expected_status=200

Start DL traffic for UE ${ue_id} on bearer ${bearer_id} via ${protocol} at ${speed} Mbps
    [Documentation]    Uruchamia ruch Downlink dla wskazanego UE i bearera.
    ${numeric_ue}=     Convert To Integer    ${ue_id}
    ${numeric_bearer}=    Convert To Integer    ${bearer_id}
    ${body}=           Create Dictionary    protocol=${protocol}    Mbps=${speed}
    POST On Session    epc_session    /ues/${numeric_ue}/bearers/${numeric_bearer}/traffic    json=${body}    expected_status=200

Fetch traffic stats for UE ${ue_id} on bearer ${bearer_id}
    [Documentation]    Pobiera statystyki ruchu dla konkretnego bearera i zapisuje odpowiedź.
    ${numeric_ue}=     Convert To Integer    ${ue_id}
    ${numeric_bearer}=    Convert To Integer    ${bearer_id}
    ${resp}=           GET On Session    epc_session    /ues/${numeric_ue}/bearers/${numeric_bearer}/traffic    expected_status=any
    Set Test Variable  ${last_response}    ${resp}

Verify that UL traffic is exactly 0 bps
    [Documentation]    Weryfikuje, czy ruch Uplink (rx_bps) wynosi 0.
    ...                Jeśli rx_bps > 0 — symulator błędnie generuje ruch w obu kierunkach.
    ${stats}=          Set Variable    ${last_response.json()}
    Should Be Equal As Integers    ${stats['rx_bps']}    0
    ...                msg=Błąd Wykryto ruch UL (rx_bps=${stats['rx_bps']}).
    Log                tx_bps=${stats['tx_bps']} rx_bps=${stats['rx_bps']}    level=WARN