*** Settings ***
Documentation       Orders robots from SobotSpareBin Industries Inc.
...                 Saves the    order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${DOWNLOAD_PATH}=                   ${OUTPUT DIR}
${ORDERS_CSV}=                      https://robotsparebinindustries.com/orders.csv
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${OUTPUT DIR}${/}temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get Value From User    Give the path to file of orders you want to use    default_value=${ORDERS_CSV}
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    ${secrets}=    Get Secret    url
    Open Browser    ${secrets}[order_page]    browser=chrome
    Maximize Browser Window

Get orders
    Download    ${ORDERS_CSV}    target_file=${DOWNLOAD_PATH}
    ${orders_csv}=    Read table from CSV    ${DOWNLOAD_PATH}/orders.csv
    RETURN    ${orders_csv}

Close the annoying modal
    Click Button When Visible    //button[@class='btn btn-dark']

Fill the form
    [Arguments]    ${row}
    Click Element When Visible    //select[@id='head']/option[@value='${row}[Head]']
    Click Element When Visible    //input[@id='id-body-${row}[Body]']
    Input Text    //input[@class='form-control']    ${row}[Legs]
    Input Text    //input[@id='address']    ${row}[Address]

Preview the robot
    Click Button When Visible    //button[@id='preview']

Submit the order
    Click Button When Visible    //button[@id='order']
    Wait Until Element Is Visible    id:receipt

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_${order_number}_picture.png
    RETURN    ${OUTPUT_DIR}${/}robot_${order_number}_picture.png

Go to order another robot
    Click Button    //button[@id='order-another']

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order_number}.pdf
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order_number}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    target_document=${pdf}    append=${True}
    Close Pdf

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${PDF_TEMP_OUTPUT_DIRECTORY}    ${zip_file_name}
