*** Settings ***
Library    RequestsLibrary
Library    Collections
Suite Setup    Create Session    epc    http://127.0.0.1:8000
Suite Teardown    Delete All Sessions
Test Setup    Reset Simulator

*** Test Cases ***
Negative Throughput Injection — Ujemny Mbps Powinien Być Odrzucony
    [Documentation]    Sprawdza, czy API odrzuca ujemną wartość Mbps.
    Attach UE "42" To Network
    ${resp}=    Send Traffic With Negative Mbps For UE "42" On Bearer "9"
    Status Should Be Validation Error    ${resp}

*** Keywords ***
Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset

Attach UE "${ue_id}" To Network
    [Documentation]    Wysyła żądanie dołączenia UE o zadanym ID do sieci
    ${body}=    Create Dictionary    ue_id=${ue_id}
    POST On Session    epc    /ues    json=${body}    expected_status=200

Send Traffic With Negative Mbps For UE "${ue_id}" On Bearer "${bearer_id}"
    [Documentation]    Wysyła żądanie startu ruchu z ujemną wartością Mbps
    ${body}=    Create Dictionary    protocol=tcp    Mbps=${-50}
    ${resp}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic
    ...    json=${body}    expected_status=any
    RETURN    ${resp}

Status Should Be Validation Error
    [Documentation]    Weryfikuje, czy odpowiedź to błąd walidacji (400 lub 422)
    [Arguments]    ${resp}
    Should Be True    ${resp.status_code} in [400, 422]
    Log    Given error code: ${resp.status_code} Body: ${resp.text}    level=WARN