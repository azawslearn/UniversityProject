#######################
### AZ COPY COMMAND ###
#######################

$SASKey = ""

# AZ COMMAND TO UPLOAD FILES TO BLOB
.\azcopy.exe copy "C:\PSTExports\LocalSofiaUniPST.pst" "https://d431cfbe9f9b4d959dc6570.blob.core.windows.net/ingestiondata/SOFIA_UNIVERSITY_TEST/SOFIA_UNIVERSITY_PST/<SAS TOKOEN HERE>"
