*** Settings ***
Library    RequestsLibrary
Suite Setup    Create Session    epc    http://127.0.0.1:8000
Suite Teardown    Delete All Sessions
Test Setup    Reset Simulator

*** Test Cases ***
Cannot Delete Default Bearer 9
    [Documentation]    Test weryfikujący brak możliwości usunięcia domyślnego bearera o ID 9 zgodnie z dokumentacją
    Attach UE "1" To Network
    ${resp}=    Delete Bearer "9" For UE "1"
    Status Should Be Error    ${resp}

*** Keywords ***
Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset

Attach UE "${ue_id}" To Network
    [Documentation]    Wysyła żądanie dołączenia UE o zadanym ID do sieci
    ${body}=    Create Dictionary    ue_id=${ue_id}
    POST On Session    epc    /ues    json=${body}    expected_status=200

Delete Bearer "${bearer_id}" For UE "${ue_id}"
    [Documentation]    Wysyła żądanie usunięcia bearera o podanym ID dla określonego UE i sprawdza, czy operacja kończy się błędem
    ${resp}=    DELETE On Session    epc    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    RETURN    ${resp}

Status Should Be Error
    [Documentation]    Weryfikuje, czy otrzymany kod statusu odpowiedzi wskazuje na błąd (>= 400)
    [Arguments]    ${resp}
    Should Be True    ${resp.status_code} >= 400
    Log    Given error code: ${resp.status_code} Body: ${resp.text}    level=WARN