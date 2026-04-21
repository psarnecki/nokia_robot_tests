*** Settings ***
Documentation       Matematyka agregacji ruchu
Library             RequestsLibrary
Library             Collections
Library             BuiltIn

*** Variables ***
${BASE_URL}         http://localhost:8000
${DEFAULT_BEARER}   9

*** Test Cases ***
Traffic Aggregation Math (Consistency of /ues/stats)
    [Documentation]    Uruchamia ruch na trzech różnych UE i sprawdza statystyki.
    
    Reset EPC Simulator
    
    Attach UE with ID 1
    Attach UE with ID 2
    Attach UE with ID 3
    
    Start DL traffic for UE 1 on bearer ${DEFAULT_BEARER} via udp at 5.0 Mbps
    Start DL traffic for UE 2 on bearer ${DEFAULT_BEARER} via udp at 10.0 Mbps
    Start DL traffic for UE 3 on bearer ${DEFAULT_BEARER} via udp at 15.0 Mbps
    
    Verify connected UE count is 3
    Verify total Tx traffic is 30000000 bps


*** Keywords ***
Reset EPC Simulator
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]   Wysyła żądanie dołączenia urządzenia UE do sieci.
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${body}=           Create Dictionary    ue_id=${numeric_id}
    ${resp}=           POST On Session    epc_session    /ues    json=${body}
    Status Should Be   200    ${resp}

Start DL traffic for UE ${ue_id} on bearer ${bearer_id_str} via ${protocol} at ${mbps_str} Mbps
    [Documentation]    Rozpoczyna transfer danych w kierunku Downlink (DL) dla wskazanego UE i kanału (bearer), przy użyciu określonego protokołu i prędkości.
    # Convert to numbers for JSON body
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${mbps}=           Convert To Number     ${mbps_str}
    ${body}=           Create Dictionary    protocol=${protocol}    Mbps=${mbps}
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}/traffic    json=${body}
    Status Should Be   200    ${resp}

Verify connected UE count is ${expected_count}
    [Documentation]    Pobiera zagregowane statystyki z API i weryfikuje, czy aktualna liczba podłączonych urządzeń (ue_count) zgadza się z oczekiwaną.
    ${stats_resp}=     GET On Session    epc_session    /ues/stats
    Status Should Be   200    ${stats_resp}
    ${stats}=          Set Variable    ${stats_resp.json()}
    Should Be Equal As Integers    ${stats['ue_count']}    ${expected_count}

Verify total Tx traffic is ${expected_tx} bps
    [Documentation]    Sprawdza całkowity ruch z marginesem błędu +/- 5%.
    
    Sleep    2s
    
    ${stats_resp}=     GET On Session    epc_session    /ues/stats
    ${stats}=          Set Variable    ${stats_resp.json()}
    ${actual_tx}=      Set Variable    ${stats['total_tx_bps']}

    ${lower_bound}=    Evaluate    int(${expected_tx} * 0.95)
    ${upper_bound}=    Evaluate    int(${expected_tx} * 1.05)
    
    Log    Oczekiwano: ${expected_tx} bps
    Log    Zarejestrowano: ${actual_tx} bps (Akceptowalny zakres: ${lower_bound} - ${upper_bound})
    
    Should Be True     ${actual_tx} >= ${lower_bound} and ${actual_tx} <= ${upper_bound}
    ...    msg=Błąd! Oczekiwano ruchu w okolicach ${expected_tx} bps, ale otrzymano ${actual_tx} bps.