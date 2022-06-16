# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.RPA.RobotLogListener


*** Keywords ***
Ask User to Proceed
    ${proceed}    Set Variable   False
    Add icon      Success
    Add heading   Let's get them robots!!
    Add submit buttons    buttons=Yes,No    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        ${proceed}    Set Variable    True
    END
    [return]    ${proceed}


Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite= True

Get orders
    Download The CSV File
    ${my_orders}=    Read table from CSV    orders.csv
    [return]    ${orders}


Close the annoying modal
    ${found}=     Run keyword And Return Status    Wait Until Page Contains Element    class:modal-content    timeout=3    error=false
    IF    ${found}
       
        Click Button    OK
    END

*** Keywords ***
Fill the form
    [Arguments]    ${data}
    
    Select From List By Value    id:head    ${data}[Head]    
    Click Button    id:id-body-${data}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${data}[Legs]
    Input Text    id:address          ${data}[Address]

Preview the robot
    Click Button                     id:preview
    FOR    ${i}    IN RANGE    5
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:robot-preview-image
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:preview
            Sleep    1
        END
    END

Submit the order
    Click Button                     id:order
    FOR    ${i}    IN RANGE    5
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:receipt
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:order
            Sleep    1
        END
    END 


Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${sales_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_receipt_html}    ${CURDIR}${/}output${/}recipts_${order_num}.pdf
    [return]    ${CURDIR}${/}output${/}recipts_${order_num}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}robot_ss__${order_num}.png
    [return]    ${CURDIR}${/}output${/}robot_ss_${order_num}.png

Embed the robot screenshot to the receipt PDF file    
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To PDF    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}    coverage=0.2
   # Close Pdf    ${pdf}
Go to order another robot
    Click Button                     id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output      ${CURDIR}${/}output${/}final_receipts.zip   include=*.pdf

Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${proceed}=    Ask User to Proceed
    IF    ${proceed}
        ${my_orders}=    Get orders
        Open the robot order website
        FOR    ${data}    IN    @{my_orders}
             Close the annoying modal
             Fill the form    ${data}
             Preview the robot
             Submit the order
             ${pdf}=    Store the receipt as a PDF file    ${data}[Order number]
             ${screenshot}=    Take a screenshot of the robot    ${data}[Order number]
             Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
             Go to order another robot
        END
        Create a ZIP file of the receipts
    END
    [Teardown]    Close The Browser

