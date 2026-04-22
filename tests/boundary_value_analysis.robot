*** Settings ***
Documentation       Boundary Value Analysis — walidacja granic wejściowych API
Library             RequestsLibrary
Library             Collections

Suite Setup         Create Session    epc    http://127.0.0.1:8000
Suite Teardown      Delete All Sessions
Test Setup          Reset Simulator

*** Test Cases ***
BVA - UE ID Out Of Range Should Return 422
    [Documentation]    ue_id=101 jest poza zakresem 0-100. API powinno zwrócić 422.
    ${resp}=    POST On Session    epc    /ues
    ...    json={"ue_id": 101}    expected_status=any
    Should Be Equal As Integers    ${resp.status_code}    422

BVA - Bearer ID Out Of Range Should Return 422
    [Documentation]    bearer_id=10 jest poza zakresem 1-9. API powinno zwrócić 422.
    Attach UE With ID    1
    ${resp}=    POST On Session    epc    /ues/1/bearers
    ...    json={"bearer_id": 10}    expected_status=any
    Should Be Equal As Integers    ${resp.status_code}    422

BVA - Invalid Protocol Should Return 422
    [Documentation]    protocol="http" jest nieprawidłowy (tylko tcp/udp). API powinno zwrócić 422.
    Attach UE With ID    1
    ${resp}=    POST On Session    epc    /ues/1/bearers/9/traffic
    ...    json={"protocol": "http", "Mbps": 10}    expected_status=any
    Should Be Equal As Integers    ${resp.status_code}    422

*** Keywords ***
Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset

Attach UE With ID
    [Documentation]    Dołącza UE o podanym ID do sieci
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    POST On Session    epc    /ues    json=${body}    expected_status=200
