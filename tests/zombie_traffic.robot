*** Settings ***
Documentation       Weryfikuje sieroce statystyki i wycieki ruchu po twardym usunięciu.
Library             RequestsLibrary
Library             Collections

Test Setup          Reset EPC Simulator

*** Variables ***
${BASE_URL}         http://localhost:8000

*** Test Cases ***
Ghost Traffic Prevention (Hard UE Detach)
    [Documentation]    Dołącza UE, dodaje kanał, odpala ruch i nagle odłącza całe urządzenie UE. 
    ...                Weryfikuje, czy symulator poprawnie ubija procesy w tle, a statystyki spadają do zera.
    
    Attach UE with ID 1
    Add bearer 5 to UE 1
    Start DL traffic for UE 1 on bearer 5 via udp at 1000 Mbps
    
    Verify total Tx traffic is greater than 0 bps
    
    Detach UE with ID 1
    
    Verify connected UE count is 0
    Verify total Tx traffic is exactly 0 bps

Ghost Traffic Prevention (Hard Bearer Delete)
    [Documentation]    Dołącza UE, dodaje kanał i odpala ruch. Tym razem usuwa tylko sam kanał (Bearer), 
    ...                zostawiając urządzenie UE podłączone. Weryfikuje usunięcie ruchu tylko dla tego Bearera.
    
    Attach UE with ID 2
    Add bearer 4 to UE 2
    Start DL traffic for UE 2 on bearer 4 via udp at 1000 Mbps
    
    Verify total Tx traffic is greater than 0 bps

    Delete bearer 4 from UE 2
    
    Verify connected UE count is 1
    Verify total Tx traffic is exactly 0 bps


*** Keywords ***
Reset EPC Simulator
    [Documentation]    Resetuje środowisko (wymagane jako podstawa izolacji testów).
    Create Session     epc_session    ${BASE_URL}
    POST On Session    epc_session    /reset

Attach UE with ID ${ue_id}
    [Documentation]   Wysyła żądanie dołączenia urządzenia UE do sieci.
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${body}=           Create Dictionary    ue_id=${numeric_id}
    ${resp}=           POST On Session    epc_session    /ues    json=${body}
    Status Should Be   200    ${resp}

Detach UE with ID ${ue_id}
    [Documentation]    Odłącza urządzenie UE od sieci (Hard Detach).
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${resp}=           DELETE On Session    epc_session    /ues/${numeric_id}
    Status Should Be   200    ${resp}

Add bearer ${bearer_id_str} to UE ${ue_id}
    [Documentation]    Dodaje dedykowany kanał transportowy (Bearer) dla podłączonego UE.
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${body}=           Create Dictionary    bearer_id=${bearer_id}
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers    json=${body}
    Status Should Be   200    ${resp}

Delete bearer ${bearer_id_str} from UE ${ue_id}
    [Documentation]    Usuwa konkretny kanał transportowy z UE (Hard Delete).
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${resp}=           DELETE On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}
    Status Should Be   200    ${resp}

Start DL traffic for UE ${ue_id} on bearer ${bearer_id_str} via ${protocol} at ${speed_str} ${unit}
    [Documentation]    Rozpoczyna transfer danych w kierunku Downlink (DL).
    ${numeric_id}=     Convert To Integer    ${ue_id}
    ${bearer_id}=      Convert To Integer    ${bearer_id_str}
    ${speed}=          Convert To Number     ${speed_str}
    ${body}=           Create Dictionary    protocol=${protocol}    ${unit}=${speed}
    ${resp}=           POST On Session    epc_session    /ues/${numeric_id}/bearers/${bearer_id}/traffic    json=${body}
    Status Should Be   200    ${resp}

Verify connected UE count is ${expected_count}
    [Documentation]    Weryfikuje aktualną liczbę podłączonych urządzeń (ue_count).
    ${stats_resp}=     GET On Session    epc_session    /ues/stats
    Status Should Be   200    ${stats_resp}
    ${stats}=          Set Variable    ${stats_resp.json()}
    Should Be Equal As Integers    ${stats['ue_count']}    ${expected_count}

Verify total Tx traffic is greater than ${min_tx} bps
    [Documentation]    Sprawdza, czy ruch w ogóle występuje przed przystąpieniem do testu usuwania.
    ${min_numeric}=    Convert To Integer    ${min_tx}
    ${stats_resp}=     GET On Session    epc_session    /ues/stats
    ${stats}=          Set Variable    ${stats_resp.json()}
    Should Be True     ${stats['total_tx_bps']} > ${min_numeric}    msg=Ruch nie wystartował!

Verify total Tx traffic is exactly ${expected_tx} bps
    [Documentation]    Weryfikuje rygorystycznie 0 bps po usunięciu obiektu.
    ${stats_resp}=     GET On Session    epc_session    /ues/stats
    ${stats}=          Set Variable    ${stats_resp.json()}
    Should Be Equal As Integers    ${stats['total_tx_bps']}    ${expected_tx}    msg=Znaleziono sierocy ruch!