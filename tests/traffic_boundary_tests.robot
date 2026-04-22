*** Settings ***
Library         RequestsLibrary
Suite Setup     Create Session    epc    http://127.0.0.1:8000
Suite Teardown  Delete All Sessions
Test Setup      Reset Simulator

*** Test Cases ***

Traffic Over 100 Mbps Limit
    [Documentation]    Test weryfikujący, czy aplikacja poprawnie blokuje żądanie rozpoczęcia transferu przekraczającego ustalony limit górny (100 Mbps)
    Attach UE "1" To Network
    ${resp}=    Start Traffic For UE "1" On Bearer "9" With Mbps 110
    Run Keyword If    ${resp.status_code} == 200    Fail    Serwer pozwolił na włączenie transferu o prędkości powyżej limitu na jednym bearerze
    Status Should Be Error    ${resp}

Negative Transfer Speed Should Be Rejected
    [Documentation]    Test weryfikujący brzegową wartość dolną, system nie powinien pozwalać na przesyłanie prędkości ujemnych
    Attach UE "2" To Network
    ${resp}=    Start Traffic For UE "2" On Bearer "9" With Mbps -10
    Run Keyword If    ${resp.status_code} == 200    Fail    Serwer pozwolił na włączenie transferu o ujemnej prędkości
    Status Should Be Error    ${resp}

*** Keywords ***

Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset    expected_status=any

Attach UE "${ue_id}" To Network
    [Documentation]    Wysyła żądanie dołączenia UE o zadanym ID do sieci
    ${body}=    Create Dictionary    ue_id=${ue_id}
    POST On Session    epc    /ues    json=${body}    expected_status=200

Start Traffic For UE "${ue_id}" On Bearer "${bearer_id}" With Mbps ${mbps}
    [Documentation]    Wysyła żądanie startu ruchu, ale pozwala na dowolny status odpowiedzi
    ${body}=    Create Dictionary    protocol=tcp    Mbps=${mbps}
    ${resp}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${resp}

Status Should Be Error
    [Documentation]    Weryfikuje, czy otrzymany kod statusu odpowiedzi wskazuje na błąd walidacji lub logiki
    [Arguments]    ${resp}
    Should Be True    ${resp.status_code} >= 400
    