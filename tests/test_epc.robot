*** Settings ***
Library    RequestsLibrary
Library    Collections
Suite Setup    Create Session    epc    http://127.0.0.1:8000
Suite Teardown    Delete All Sessions

*** Keywords ***
Reset Simulator
    [Documentation]    Resetuje stan symulatora EPC do wartości początkowych
    POST On Session    epc    /reset

Attach UE To Network
    [Documentation]    Wysyła żądanie dołączenia urządzenia UE do sieci
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    ${resp}=    POST On Session    epc    /ues    json=${body}    expected_status=200
    [Return]    ${resp}

Status Should Be Attached
    [Documentation]    Sprawdza, czy odpowiedź zawiera status "attached"
    [Arguments]    ${response}
    Dictionary Should Contain Value    ${response.json()}    attached

*** Test Cases ***
Attach UE To Network - Happy Path
    [Documentation]    Poprawne dołączenie UE do sieci
    [Setup]    Reset Simulator
    ${resp}=    Attach UE To Network    ${1}
    Status Should Be Attached    ${resp}