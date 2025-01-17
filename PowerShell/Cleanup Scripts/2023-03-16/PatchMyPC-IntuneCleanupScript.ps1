#Requires -Modules MSAL.ps

<#
.SYNOPSIS
    Clean Duplicate Intune Apps and Updates that may have been created due to an issue on March 16, 2023
.DESCRIPTION
    Clean Duplicate Intune Apps and Updates that may have been created due to an issue on March 16, 2023
.PARAMETER ClientId
    Specifies the Client ID (Application (Client) ID) of the Intune App Registration used to connect to Intune
.PARAMETER TenantId
    Specifies the Tenant ID (Directory (tenant) ID) of the Intune App Registration used to connect to Intune
.EXAMPLE
    PatchMyPC-IntuneCleanupScript.ps1 -ClientId "GUID" -TenantId "GUID"
    Authenticates against Graph, Finds potential duplicate apps, prompts for their removal, and removes the duplicate Intune Apps and Updates after confirmation.
.NOTES
    ################# DISCLAIMER #################
    Patch My PC provides scripts, macro, and other code examples for illustration only, without warranty 
    either expressed or implied, including but not limited to the implied warranties of merchantability 
    and/or fitness for a particular purpose. This script is provided 'AS IS' and Patch My PC does not 
    guarantee that the following script, macro, or code can or should be used in any situation or that 
    operation of the code will be error-free.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId
)

#region config
$updateIdsToClean = @(
    "cc9327ef-c9bf-4358-9093-af341e94e7c7",
    "07191351-e880-4cda-a80e-b442849c5236",
    "2d6ef80e-d570-4642-895d-e5c0cb84bbd4",
    "3a2bd521-6960-4c2c-8db8-46a99cfa5c6d",
    "8f44a272-e398-44fd-8f01-b6496a65d095",
    "e6d3b32c-56b5-42ad-8800-10ee978f736c",
    "97c0288d-7baf-4ad8-9c70-d7f7b5c6b22f",
    "7c91406e-e98d-41b7-aa89-25462bc70525",
    "e708c474-9420-4d58-8047-87a0c253d67a",
    "aeea98cd-87e8-4f8c-aefa-ec759c87ca02",
    "9a10ee58-a7f8-4f93-b68a-ca96ef2547b1",
    "10474756-9670-42dc-a9b6-ca65dcb761d9",
    "05864d7c-8e6c-4668-9971-0c6959178b91",
    "a64cfef5-f640-498a-b53a-e9a0eef9b30e",
    "0d7813df-2aa8-454e-b943-c49cf8de39d4",
    "637b6681-ba5b-49d7-a68c-3a887e5d5493",
    "4e370625-6a5d-4310-95c9-9292c66c8394",
    "960f18cf-a532-43ea-8d6f-bcd8d24c4aac",
    "d86697ce-afdd-4080-873c-6ffce6ebc80a",
    "940a66e5-112c-466f-8fee-8fd825d658cf",
    "67fb9e49-e97b-460e-87b4-8ce7b272dd4b",
    "eb18b057-4153-44ba-80ff-b456345374bd",
    "c99d2d7c-6bd7-44f7-b79c-086cc41cbb07",
    "32ab50d8-bed0-4da6-ba4f-69428340d3f4",
    "d24c6a62-e6fe-4a8c-a94e-77a6c6c40eb8",
    "df907712-b38d-42d3-976a-230a1508aa11",
    "60c9a15f-4ca8-4eb3-8bbf-5a1f26886f58",
    "ed888c2f-516b-4d6c-9460-88b4980a1fd1",
    "368d6944-b774-410d-8d0a-7a7b00ba7be4",
    "bccdd622-d1d3-408d-ad2f-07bedd4138dc",
    "569ad753-bfe3-4d9a-9cef-8f293af6989b",
    "445c4830-55ad-45d6-b505-c1cd8fc52a6a",
    "ed6a528a-80c7-4448-aa28-ca7276a71b3f",
    "7c505deb-73f8-4eb1-bf37-f1a1ea5bad3e",
    "e51e0ae2-6660-470d-86e2-1a24a503500a",
    "78c2e2a5-26be-49c3-b3bb-ac54a116798e",
    "753a9ec8-581e-4009-bbb9-baa56921183c",
    "d28a8dd9-699e-49b4-ba9d-0358fdf2b774",
    "12d03b65-5b96-4f56-9113-5949898c5eaa",
    "a5c8c218-0f48-4689-b5c6-76110de3b596",
    "3095613c-8337-4b36-95fd-ae80ff62091a",
    "39b1ba82-66ac-44a6-bd6a-38ec6b514b94",
    "2985034c-4d94-45c8-af84-191d3e87a100",
    "e9f7647e-602c-4212-a68f-8bbe99c5fa13",
    "915d92ae-ade4-4c9c-9bbd-8447a9903599",
    "3483e14b-66e3-4452-8cf8-4f86fe0d56a1",
    "aab2c57c-912b-459e-81df-216b6ccc8a25",
    "f732cb16-1104-4420-b3c7-1379b14ceab5",
    "0caa6ad1-3772-43de-a275-d452c830f40f",
    "28cc9ebf-99b9-464d-88d8-3d90e47df9e8",
    "e3af24ba-68b4-491b-b8db-48d5bed1952f",
    "2bc79dc9-c7db-466f-a0de-9de968ab103c",
    "a2592c90-933f-4d00-8a13-b4d00e199242",
    "fd2dde0b-6b58-4838-a552-b9c18ea40131",
    "0e3b420f-3fcd-4282-8c76-30ef34d26440",
    "3a44df42-0a6b-49a0-bc49-d94b0ff78deb",
    "19d8727a-c766-45ea-ac5b-9edc1ade22f8",
    "4083c4a5-3e38-4b1b-888c-9a9b22fa1d6d",
    "1adbfa49-6de2-4fc9-918e-08428d793793",
    "fd691431-0e63-4e01-8c06-5903175ea96e",
    "fb6ecd30-8273-488a-85a4-c3021e468f9c",
    "cbfdec6c-da1f-46f0-a682-3d92d529c9f0",
    "acc80dba-98cd-4649-b4d2-8c5ec7a713ba",
    "8143534f-d49b-4f2c-9fff-619e55f8d0c0",
    "70ea1e78-d744-4bae-b77b-5e395c02ca2a",
    "f7bbb05b-6d16-4273-9eb8-7147a84b0b2b",
    "a6716f4d-a0f9-42f5-9396-b54497e8c4e0",
    "b251e42e-83d7-4f2c-941e-b34c0b7508ad",
    "84ae0ca1-dec4-447b-91a0-41e79fe3be5a",
    "bbdcbb98-6dc6-4b26-84d2-2f11716a56ea",
    "507811ce-46f5-4180-b372-70e30144f9fe",
    "0120aa7c-4881-477a-83f2-e0d9038b7425",
    "5c3fba4d-1db4-4bbc-bb2b-974ee45da55b",
    "573eae8a-5778-450e-854b-b8db627d1d5d",
    "50a5f6ce-776d-456e-bef7-83da5c19325e",
    "41b8c9ef-0048-4c47-a714-2f185cc42315",
    "931e4819-38bb-4710-9f2d-9630498f3953",
    "00ffe931-f16a-429a-9c41-52ac9bb2fb50",
    "6b75c160-21bb-4fa7-af96-eb6a1bce0163",
    "0d1fd7dd-5f90-4886-b815-5227259633de",
    "698223ae-0fa0-4c6b-8449-c9837f134d66",
    "51e58fea-8886-4c69-a370-39d00f5ad248",
    "496ad9a3-5c47-4dfc-abef-6b43f415c705",
    "3b00d157-9b5f-46cc-a5d0-914cc917d59f",
    "394c8f6e-f683-4478-9a75-798d44cb3f7f",
    "c2e23bac-2b0a-4cbe-a8ff-6c15ecda85c6",
    "2b314841-be52-495a-882d-54fcbfc73085",
    "1d038a6b-fc25-484b-b96b-c07c56765d8e",
    "359b3aaf-5de3-4a0d-86a3-66324d2c6685",
    "3cd1e614-8492-40cf-af6f-0de51efff70a",
    "89d649eb-6172-4618-9539-473296fe0ec5",
    "d5f8125b-d29c-4163-8ef2-86c0b122565d",
    "053577b5-eba0-49eb-92cc-f8e589bcc951",
    "dc62c2bf-ff1b-4c4e-8cbf-aa603f9cde9d",
    "7ce4faf9-72a9-4953-ad42-537796ace6bb",
    "ea528932-ad4d-4186-8f09-62c77f4072de",
    "80e660e5-f450-4bc7-bbf5-ce9c9ddd5fc1",
    "1e515533-1ed1-4ec0-82bf-44a39ad336c3",
    "fe5163bf-7e76-47fd-858c-e1d3480f6a5e",
    "898b0ded-09e5-4adc-bfb8-334427b5cd0b",
    "8e1015dc-068a-4b4f-a37a-871a0ae86469",
    "f9edd728-182f-4b84-a9fd-c167993264db",
    "dda6dc4f-6c69-43ef-8a90-38d1d90eeb35",
    "8bf7cd8c-241d-4a56-96e8-bcd31b4fbf9a",
    "346dc4dc-7039-4bf3-a9aa-320c10573b0e",
    "36a0bda8-5891-4646-8e49-980186f72849",
    "2e5a7858-1cf0-4c88-9a41-ff85acb9840e",
    "667e113e-c79e-4483-a423-371e18ab557a",
    "56a7c12d-5e04-44c8-8e68-81bdcdd96647",
    "e4599b25-340e-4e36-95dd-8d1d950c93a1",
    "989ad2ee-d82d-4f6d-b8bc-bf4a609aa298",
    "006af9bf-cf2b-4a70-8e52-eba5dab6139c",
    "6226c0de-6243-4697-ad3c-772c4b864a90",
    "df3160a3-eb4f-444d-ab88-218a87a00962",
    "77314a32-4128-4db9-bcfc-d9354417d1de",
    "eab9ff1e-d072-4f32-a909-d3539be1a872",
    "bfb0e498-96af-4259-bacc-b3e4705ff1e1",
    "da7fa4eb-6f56-4cf9-848c-49919e95ca89",
    "02cf2ccc-8259-4971-be7d-23d23da08f3f",
    "832e7206-78b0-4c1f-92c0-e50572a3229f",
    "4bb21375-d79f-4980-ab72-77c02c380f74",
    "f81db5d5-ae43-4f1b-a366-fca2b79f6d47",
    "505e3567-b386-4b24-b4bb-64499a8fd993",
    "cfddbfb7-ecfb-4147-9e27-e258477d1bce",
    "2d7b2ea5-9b8c-4960-b6d8-40b4a5569936",
    "e51bd23f-0b9e-4fd0-ac15-958beb5a0a42",
    "88ddfd76-bac9-4a5e-b817-c96c4dc068ac",
    "ebe5d62d-d99f-48cd-b4c9-587f765f4fa1",
    "d589f5a9-f3e6-4ca6-88bf-c1a04a0a7f7b",
    "d630c92d-af05-47a4-8e56-f626dd8f9076",
    "d613ef19-6a49-4fd5-ba91-71b6e2d34ae0",
    "4e72b433-8f3a-4af0-b637-4275eeca150a",
    "4c737ef6-794a-4cff-b969-1e3ec8b0361c",
    "d0633729-df45-4157-9a8d-04a9dc37199d",
    "0ab6d314-f5ca-4cb2-9602-530f3538699b",
    "1745ed46-f4c1-44fb-8da0-165ab88b2e56",
    "b2f47bc6-637e-4164-a2a6-defcebd25757",
    "fd722a22-9798-43ee-9649-19eabffdf95b",
    "5ba56ceb-89d4-4331-8590-be284510cc61",
    "eb2e1511-0d84-4f99-ae02-da0a210d4450",
    "73b4af8a-cbe0-4347-947b-dae11fc48d57",
    "11245bde-c6a6-4857-8ec9-534df43c7e8c",
    "fc5fef3b-02e4-4c10-967c-e23217d2debc",
    "c51b0d23-b795-4c2e-a0d2-e8c2f746890f",
    "011f5090-e62b-44b5-979e-9e8efa51e47c",
    "ef03899d-a60c-47c1-a270-f3bb3a4b93de",
    "e89c4ddf-b575-4ff0-b0c3-7808b345066e",
    "a2a964cd-28d3-44b9-974c-aa947693a0f7",
    "2c36756c-8dfc-4a78-8a12-549bfbcc7198",
    "8ef791c5-d550-4590-aead-87c8b34f1023",
    "aee352ea-e7f6-4e2a-901c-f344412c4655",
    "793db7b0-5511-44e3-b9a1-6c02ded298a7",
    "107b0578-9794-414a-bc3d-ceca272d96c0",
    "c37ef8b9-e467-445a-b45b-fba261b7a1af",
    "5eec235f-1739-45f3-a826-b32b0d520779",
    "c43ad2f2-36fc-4ebf-ac57-95ea565a1cbb",
    "5e53619d-06c1-469d-95c8-b5e68fb6c234",
    "1752a6a0-5b9e-4bc9-957f-39d43d0fb2ce",
    "5cbc9bf8-d547-47b7-afec-3dacda87ec65",
    "69c8077f-1ac2-4e6a-96c7-dd6b1f1bdf9b",
    "b84560ba-6764-4c39-9330-27751bfb05dd",
    "71e2c4c8-7977-46f7-a0a2-f3ff6157823c",
    "fff2caed-62b7-4011-bcb0-20b4bbed8270",
    "7a8ccb7b-fd2f-4f08-8581-7adb9c1ab08e",
    "146a3335-0b3a-41a6-ae71-b609b28edc07",
    "a1a0b8cd-8392-42e9-808f-f59a1ecfd088",
    "97aeebfb-a860-4fd1-80ac-e6e5f054ccfc",
    "ef4cb98a-7b99-4536-bbac-ebaab24b36b9",
    "357385e3-8816-43f8-b5d7-65c343772f83",
    "053d78a8-6ff3-4b43-8398-e0f21887d3a9",
    "3c74424c-60d2-4674-8d32-1e7ee9a7a74e",
    "d3e191bc-8399-4484-a1cb-d23f6c01e05a",
    "6e56e544-7824-44f8-a753-15f86ece6781",
    "98a9e0b3-f15c-4059-987e-0a606b4e31c5",
    "b4a7ead8-da50-4383-a3a1-d7f547126ac0",
    "fb138fb5-44f3-4ffc-9251-bd050072aeee",
    "655e496f-754e-4a9b-81bf-e21ebb4535ac",
    "a3680757-7ccd-4957-ba1a-6ff544352549",
    "45262b49-4986-452d-a845-9e742741e9cd",
    "ec3d3596-ee41-48d0-9278-27affc88d104",
    "b427efbf-26f8-46b6-9e58-3f4869bb0790",
    "0a808416-3731-4c2b-abc4-7dcc8a3efcef",
    "319f6123-4a98-414a-8955-401a65ad348e",
    "dea83b7e-5ba0-4f75-b02f-1f6d11015be4",
    "dbb9e690-2714-42fb-9742-d607fe8233e2",
    "63f3c38f-3fdc-4e55-b95a-31d2da7f604d",
    "0c19d5ae-8554-45c2-abad-f97ef9c3bb3f",
    "645be555-39b0-4569-9c33-715e4411f120",
    "2c4a4ccc-ff49-45e3-b684-96c8118a40e3",
    "c1757a08-b67c-49dd-b63f-1e69ef014356",
    "5ca99b75-577c-4893-bab4-ee1930670a3a",
    "31e86180-26cc-4f17-b13b-ca167eca3b52",
    "6bca0bc7-d96e-40f2-bc38-8dfc8478a6a9",
    "1c6e7db1-e3c4-4e01-ac2a-852a91ea5563",
    "6d480d12-8a62-4857-8856-9985415539ad",
    "761190f2-bcbc-44cc-8b2f-bedac0298183",
    "92e6ece6-bbd7-43a8-9049-a9ff0acde1ca",
    "2ec77824-6c28-42a6-b8a2-14df7369595f",
    "e5885cc7-8bf2-4bd7-bf34-f3123619f321",
    "ef947b3c-fe1f-4510-a632-85ad29c18859",
    "23ee2802-71cf-4c66-acba-002ab57a8356",
    "6d7e04b8-568b-4e90-8a28-f309871cb6db",
    "5be4e4fc-9470-416b-a4b6-26a1467942b8",
    "5a2529dd-3d6a-4304-bd85-ebce51b02f75",
    "ec6a9cc0-1a7b-4942-8f4d-e10cd40d47c9",
    "d5b862cd-9e85-476a-a6dd-3d4d0a03a592",
    "81a92f49-a784-4a3e-a1b2-1cc30126a538",
    "34cf24bd-d7fc-4edd-b4dd-b2f1d9736205",
    "c1614a6f-4fdb-4338-8238-b13a0bd8934e",
    "c320522c-3b73-4d90-b76a-a777b441e087",
    "0f0f46a4-491c-4b10-9ed1-eeab4bcb4385",
    "52cc9707-6241-4bd4-b5d6-5f17704c7327",
    "b64bcd22-f581-4eb0-8f69-ddddeb0f3dba",
    "1adac2f2-e1d1-4cae-a542-413a499d03a2",
    "e8a01c38-87a1-4c6b-98a4-d895e94e6c09",
    "0f35948b-a29b-48ad-9dab-0f34f3193995",
    "b3ed6d6e-2387-4410-974f-c19c91fcc7b9",
    "4a0c6352-9de0-4684-ae2f-52e30952e532",
    "2a380974-d9db-4fe4-bbd5-694bc362749e",
    "fd042966-b430-4348-afc3-cea3d857b904",
    "d92a783a-0397-4794-9ff3-2f89f17f41f1",
    "75f6cda2-1201-4bc6-b8e3-78e9316ae52c",
    "50ac3881-6154-4063-bb51-e5e00906bc76",
    "edad85a7-c154-4d36-ad17-97519bbe53c3",
    "bca9401d-d0e9-44ab-8958-acdf2d0bc4a7",
    "343d7b0a-abb8-489a-b79a-219429ee5891",
    "4a2c2468-fda7-485e-a671-daddf77ee8ea",
    "f2380900-3b92-452b-95ee-d22861a23e50",
    "1912d803-5bcf-41c7-a954-3d4a6a4d542d",
    "d4347436-74c8-4b60-b4db-534b839f0dd9",
    "93b44ed0-61c1-4487-a23e-5a3376f5d0b2",
    "84d4945d-c745-4091-add1-89be39033603",
    "5b502382-3207-4a69-a641-e245acd66bbc",
    "6e251029-0289-47ac-9de4-446a6e14ba30",
    "3b063138-6b73-4b5f-a6bc-d5a1a1053a2e",
    "b128557b-672a-46b5-b5b5-235aa2775fc4",
    "e31b6e86-1ee9-4f7a-a9ba-14a4361da968",
    "184981b9-ce8a-4813-8f1b-0f31b0aa55a4",
    "c3d3913d-72e5-4a1c-8bca-dbfe02833fdf",
    "4432a0cb-285a-4918-89e8-8ff3b5a98140",
    "3cc042d0-4f7a-410e-aaca-4c4e3c7842da",
    "3e2db37f-1522-4e68-876b-c6c7f4550181",
    "bb5ffaff-1a00-4d7b-9a49-6ff34f627381",
    "f5fd9fe3-3fc2-4cf3-9b28-5e8fd449aad7",
    "b42d6b32-7676-451a-a501-cfd1852eda81",
    "e63823a1-a039-42da-b3b3-030fc14ace6c",
    "2623eed0-37f6-4abd-b6f4-f2d31d93167d",
    "fe674fbc-85ff-4a8c-b099-9fad1b194abb",
    "2b076b3b-7a2d-4c2c-9c10-232223dd5dac",
    "c01d6713-1ddb-4b92-bc37-a975dab38a3e",
    "db10d7d9-9d06-4f01-9aac-b6d5edef1090",
    "939cc222-a65b-41bb-8ccd-4501ce3646f2",
    "146a964d-0260-4170-b5c7-3004f8465300",
    "851e2149-bf1e-4a6f-9ed4-8ae182b0e711",
    "9e1fba95-08c3-48f2-bc4f-61e68d9b8ee1",
    "24dd9df2-7e9c-431e-8f76-dc925f03d644",
    "70d10f1a-e7ef-417c-b35d-a36d3457b884",
    "26237cf9-1a71-4e20-a3fc-4e4af9d9e46c",
    "da4c2ef2-a249-4ad1-89eb-757563cc0520",
    "f566c2de-31e3-4939-b7f3-06be0e832524",
    "8c3d9bd4-3f19-47a5-8f75-bf9e243a89bd",
    "9f4e8b71-4cf5-4d89-a68b-32ee29eb74b0",
    "a68c78b8-0a45-480c-816f-637b12e2adb4",
    "ff538791-2ea1-4c97-ba78-bacf828096a2",
    "5996d67a-2eb5-4c05-90bc-7665d4dc8bbc",
    "413dfc93-371b-4b19-b95b-3ff9dd9ed989",
    "0c83d666-f069-4644-8d97-37d8f11d8d2c",
    "b29b9c36-3b94-448b-8f26-0cefdc979554",
    "2d21df87-e937-4774-a8bf-b2aa6bdb8804",
    "34ffe6ff-abe6-48a5-94b0-dfb400948dad",
    "1abd67dd-69d4-4604-88c4-6031b0732a99",
    "630d7c7e-5d95-4983-ba24-fc51103e5d9f",
    "375cb467-c191-46e4-9201-52086894abf2",
    "94ef93e8-55f9-4da9-b137-1ca423f184a0",
    "eec9a518-5123-43ae-8848-837cd7adc0d9",
    "61f7ff98-51db-4677-9c59-d6acefe34740",
    "cc37574a-0d02-424b-a749-b178667437a8",
    "c8432740-7d59-4dd8-88a5-b1451b066dd5",
    "d8cbdf7b-96ed-465a-910a-6c30fb67fd27",
    "f5abbab0-7380-4745-83d0-eb1157df93c2",
    "11226662-ed77-41d6-9a22-26f45fe98665",
    "6a16c12d-ec4e-40a2-a571-b8cf12bac35a",
    "27b4a165-60f8-4682-9941-f0a2c51828a3",
    "4af04570-8d9e-49ec-9b2d-d95f3d0c4e5b",
    "cd44032f-2751-4d2f-9bc3-b2872543bbc7",
    "0151d41c-0703-4c96-b9b4-a9f6476b9bc8",
    "d90cbde4-e45f-4503-8a33-cf0a32963dbe",
    "232e1ed2-61bc-4605-bda5-25ea6c6481ba",
    "f8d99f8e-0ae6-4efd-b668-4645cbe07f96",
    "c99b8dfb-639f-463a-83e8-a691226c3ee3",
    "e89187b8-ca96-46a4-8850-ee1c519c343e",
    "95597118-c02d-42f8-9f8e-2aaab079931e",
    "857104e3-ec33-4870-8c36-dff5539103cf",
    "afb8e693-c223-4fcd-8eb1-75a4fd7cf188",
    "f26f45ce-707e-4386-ab99-23098a9961b9",
    "7d6baa65-647c-4173-a135-142fc0ea9f3e",
    "4c708b54-5eec-4724-aff6-bb8727ac58ee",
    "5a7ea0ba-72a7-424a-a88b-a1b728944480",
    "185c4da2-79fc-44c8-872c-fe9c4cdd1768",
    "60816ed0-4537-4fad-8660-a43c4fdb39b1",
    "5244c707-178c-444d-997a-a382aa5c89c3",
    "f1795116-14d5-4534-b274-7e110e09889a",
    "3ca76f53-e2b2-4416-bd74-69d12a23464e",
    "bc7939af-57ce-4484-99d3-287b9bf00b8b",
    "f2e76963-6f93-440c-b4cc-7a1b3da60ea8",
    "ee850ec4-7ac6-431a-9da7-4cd4417f7ef2",
    "5e7f64d4-2db9-4801-8a58-d59342030fdb",
    "7123281e-d721-4538-8783-6e15c9992488",
    "d2d10b9b-f4e1-4104-8237-42f3a2c61e0a",
    "39cf2781-9597-4d56-8bb3-8fe871b321a8",
    "5501a526-018b-4a32-8ceb-37395653a99f",
    "7b48ec73-c6fd-4a42-b3ef-26d46360d08d",
    "732a5a90-d104-4870-8c7c-b68fd9fef651",
    "72bceaeb-4e74-451e-a71d-bb6debdc8694",
    "5b62c797-3170-4b53-a0ca-2217b9d61757",
    "9a8bdd59-8cab-4e0f-9463-8d8bda3b4fab",
    "6ebf82ec-2ecc-4f4e-ac98-09ab916eb5c0",
    "4a057020-c38b-40c9-9ed6-f72b3b18b682",
    "790de234-31c9-4c8e-af5b-5bb9aa4674f1",
    "a30138b9-3647-42b4-b7c4-4825e01bf0ea",
    "95d68a40-09d4-4ec5-b1d3-fa4bd3b16340",
    "63f26544-8329-451c-898b-d49f535afabc",
    "c5997c9b-02f2-4d66-89c1-012ea9b197d0",
    "3028568f-6f05-4979-a332-0f741d89b6e3",
    "7147ad31-080a-4198-9826-a965863dcd9a",
    "cbfb1413-76a6-443d-a91f-19a411b417f1",
    "5d0d3017-c1f8-4215-bd46-133ba02fc8aa",
    "bd0ea8ab-293d-4f20-8a61-2ff866da024d",
    "1687a1a2-872f-40e3-bdac-bfcd6820e81e",
    "3b44def3-7dd4-460c-b300-80c931f9ad52",
    "47a07281-105c-4a3d-8c9c-6b1ac9e58bbc",
    "c2d8c925-8d44-4c3b-a61f-397eb0ec03d7",
    "498f0e1b-a8ee-4b08-a534-1209e90adf0a",
    "d81ca793-e0c1-4a0e-992d-9df2b5d376cb",
    "9e3d8926-671f-4092-add7-6486b86a8b0a",
    "8b2ef8dc-dc0b-436f-87b6-f5e9c9c9e37a",
    "981a66e0-c8f3-4ebc-bd5d-fe24da96cedd",
    "3fa28d1c-5018-4f3e-98ff-64f48125fa5d",
    "7ee17f0d-690c-44c5-9df2-cb2c72ba7162",
    "121d6228-328d-480d-b427-f3aaf3125735",
    "3e121a36-d239-4cc0-b62f-794a5242b151",
    "2473731d-d534-464d-9fb0-6ccf7543d973",
    "706a9d52-1356-4b17-b071-4c4901dca561",
    "9fe281b5-bba9-4ee0-a38a-a64ecf8330e7",
    "dfba1a7f-212b-4e88-a141-d6c146555073",
    "5bef91ac-9dad-48b5-89c4-295c98f66e10",
    "afc62640-fc4d-4859-8006-209b115c2a0d",
    "f8b966d5-1608-4b9a-a592-c71356af90ac",
    "756aed4a-4ef4-4959-bd60-e8e81be78846",
    "fd0de1b1-0aa5-4a62-a8c7-eb14a0ddaffb",
    "3982d319-1e5d-4004-83cf-04faf2d09033",
    "88162843-c001-41ca-8ff3-bc7e7caaf360",
    "4fadf206-6a54-408c-b417-b07771b77124",
    "175b14ce-7d03-416d-a03b-81bb23e4f078",
    "3d326205-05c1-4829-990d-8988ef35d6b4",
    "91fdff86-7cef-4c49-bc54-a83730a8c409",
    "3a68a6f2-017d-43ac-b490-31e4c119b46b",
    "615116df-6f72-4ba2-ac9f-05d47c8c2022",
    "8a11e740-e870-47ec-929f-db8bd5c17d12",
    "d2f5cd5e-bdf8-4478-81d8-60fb5fb51866",
    "6f186aad-ac96-4fb5-ace0-f94df76215f9",
    "fd25b13b-f7ba-4713-9116-3ff789e5795c",
    "123ddc76-c963-4be6-acfb-e8c87ea18c05",
    "308c0fd4-81aa-410e-b13d-463ccf2313c2",
    "84cb1668-e462-4fcc-8924-1a9cadbab1e4",
    "20d26cc4-1ac4-4395-ad83-7d6158ff0ba8",
    "bb0b31ec-6711-4652-be95-d3adebfa6d69",
    "4a11f32c-bfb8-4da9-b2cc-6138127fc669",
    "333769c2-49d7-4d18-a99e-17f4ad8370fa",
    "9cfca2d3-7463-452b-9be7-ab1cf600feeb",
    "8a0d9bc2-77f2-4b23-8c9a-d93b6bd2d3ad",
    "00861067-72b4-49b4-986d-f9836d9767d2",
    "681f1ede-544e-4939-a76a-443ef5cf75c6",
    "0652d99d-b159-4fe0-a199-4743520bb7c9",
    "b1dd5a61-4f57-4943-8ac3-acf7641b6ad0",
    "b276140e-9cd8-4ccc-9505-129d326bdc09",
    "a26b8952-ac47-4c13-a7b4-28a5fd8a3882",
    "4db59adc-1c1a-4177-8798-fc66186ba42a",
    "eec5d98e-d469-4ed8-9af4-15241820b3ee",
    "05eecca7-5a45-4ec3-ae8d-15f4de7ca4c7",
    "046da4fd-4f49-44ca-a35f-f879d52eaf22",
    "e2d45c4e-04be-448a-85de-42caea789af8",
    "8b781c8a-7350-4661-9fa8-2028c345ea88",
    "f8ec7c52-71e2-4141-80f4-28827f4ad88f",
    "a208b716-0518-441e-a657-4108b7bf72e3",
    "01229e5f-8b78-4d5d-8652-fb940a6bebbf",
    "7c712bb6-fc31-420b-b038-2dd70d1aaa2a",
    "9ec3450b-741b-4d6b-9394-3bf9bba3c3c4",
    "e0ce4b4f-a0f0-473a-a9ac-93cc864f61bc",
    "0a239f82-2844-42d6-a754-50704e8613d2",
    "eaee27d7-8d13-4ea1-9ba1-4e8af32824e6",
    "ac8c3ee1-50dc-43fb-8896-0656490e7196",
    "06bb11c9-f9d5-4e26-a213-365337ee47cd",
    "455e1f56-5644-4141-a429-4df8cded2a2d",
    "888e257c-9da6-4620-816e-c91b0d00bd9c",
    "f9a3564d-f16d-4a80-b98a-93109e646ff3",
    "839dc313-33c3-47e8-9f9e-a570dde3052f",
    "251b626a-83c7-422d-8aec-f401e235b6fc",
    "3d388bed-e38e-4ff7-99e9-a70a89610c32",
    "91d75d49-dfee-4854-bfbe-c0c723549419",
    "584548bd-3643-42c4-84da-f533d2fd10bf",
    "2080a8c9-ac75-44ac-aec6-189149fb1133",
    "b03b2893-ee24-41bb-bd00-86a42d6f52b7",
    "e65ea22f-0946-42c5-81b3-9162c2db22d0",
    "45aad6ed-1b5b-4bb7-a1bb-9da55a2b7700",
    "a6fa533c-6e4e-4c31-a471-1ab127f8227e",
    "6309573e-b7b5-49be-b85a-cbb97bfc37b9",
    "96083080-5090-4026-9e2b-7e2039912428",
    "d1dc2dfb-dff7-4e01-8ed4-3d3906a40295",
    "eec113d5-44d4-48a1-b7ea-261f33364f17",
    "a2530b07-50bd-4d96-a672-f312f7d82a12",
    "3209c4fc-8ce4-45a0-a18e-7c09d17ea12a",
    "1a3f1a14-c43b-4fd9-b0c5-de1a942cbb90",
    "f8eeb6b3-3e00-4f74-a06d-c9bba2b0bf34",
    "1fae0372-1c5b-4047-8351-66fb0bcb1eae",
    "43309664-2ea4-43c5-816f-721944c94caf",
    "b60fe8f5-3414-4f5a-832e-993f7406e657",
    "00f09325-ed13-4dd5-8ce8-e13b24daf919",
    "07104348-bb9b-47cb-879b-f113df54ab08",
    "8fc81222-4ea9-4126-a956-2abefc840ba6",
    "57120090-a2db-4a89-b800-54a7634d5e8a",
    "05cbe31b-fb46-473e-b9cf-14b2fc728731",
    "81830a35-2594-42f0-a4ef-53edd344132c",
    "64d7930d-3f69-4072-9753-5d9bd0e47025",
    "b34e08c8-6cd8-4658-9437-a774ef571f81",
    "034697ab-e6a3-4275-8538-844b748599a8",
    "98970646-21ca-429b-9f0b-e207b370888b",
    "109dde21-64bd-4533-a542-dc1b356b5a41",
    "39a9c5bb-cd32-44fc-84c1-90ba96864725",
    "73a6c50c-a960-44d7-b8b4-508bad1af3b5",
    "5289db7d-8616-45ec-85e3-6d59fc332631",
    "33ab03f1-cf80-4fce-8492-5ba1260a68e5",
    "8ad301f4-4985-4ae3-b2bd-e8ae4eb6868f",
    "69e6a826-b33d-4b58-b8ea-c0909100c170",
    "5ca041cd-1f24-4334-8696-559683251149",
    "7560b299-bf8d-46cf-a631-dc3dbbd88396",
    "2f2eb5c0-421e-4d90-9546-516f197bd31d",
    "94f2edb7-dbf0-4c3f-b20b-e9dd64ba0b82",
    "86f3ae94-03eb-4409-8b37-3d3474d56b78",
    "f57ad0e4-6b9d-4acb-9ae1-1b737dd3415c",
    "f8e5544f-d2d7-4df9-915e-b3fa9ffec906",
    "a259d2df-0049-41cc-96df-a2fa39c2e7be",
    "e438a4e6-1d20-4342-b3d4-ccda4384abe4",
    "dcd93a6a-71f6-468a-bf5f-0b7031516a21",
    "34dccf25-7413-4b19-a88d-ce5f7b4e8be2",
    "cb31369e-6de4-4487-81c3-b4bb04f718c9",
    "7167b6cc-99c2-4a03-ad3f-9ee505c286b1",
    "58c6e25c-6d24-4766-a13a-c8f4f10da713",
    "5ec63abb-1163-41ba-8484-205753474375",
    "cf7460ac-05d9-4d62-a55b-774226f8b135",
    "733ead54-904c-4fdf-9c8e-596a7752974b",
    "ee31925e-83d1-4758-92e5-04b93b0ee806",
    "d56900ac-6a36-458e-9888-29a2f244994a",
    "781a357f-84a0-4408-a242-e61e0117922e",
    "64c8dd23-ec7f-49dd-b3ac-54356550ed7e",
    "198ca59d-b5c2-460c-9665-55f265157a6b",
    "42a7984f-18ea-49f5-8f88-7ab57e71a248",
    "5964cd98-f952-48af-a2ee-f55c15478fea",
    "99948504-b6aa-46d6-9f96-807e9efbf0f6",
    "d91cb7c9-b436-444b-a301-af070aa50f65",
    "7a545b0a-769d-4220-828a-b6ad0e82552f",
    "72b07036-085e-4530-b810-684f8f76c81e",
    "ac32acb4-9234-47bf-9aa7-f3eeadd0bec2",
    "4d4df8df-018f-4627-838f-dd56d60ffa35",
    "23c300af-6d93-44c9-af0e-a99d81b90f73",
    "e697a79d-35e3-4780-948c-2b17c7a40820",
    "fbcdb2e0-5408-4833-a619-ef053c819e1d",
    "6524b0ce-8991-4572-8e62-c9aef65b563b",
    "d2ff9ead-f3ec-4376-932e-be0c62ddb189",
    "dd99367b-e2af-4bf7-83d2-37b2126117ba",
    "d1e57f9f-d9e0-43e0-93ea-35e49e8b4230",
    "9d3149e5-fb96-42db-a526-1a907c0a9511",
    "50c89ecc-c07a-47eb-847a-ac6119014d6e",
    "7d1db0b7-c03d-4827-b7c4-36510be1d0ca",
    "f170e643-576c-4d18-9f4d-0c2342aa7015",
    "2d7bb2fd-e7d4-407e-9a71-94901725a133",
    "5d31883e-1cb2-43c9-84cf-9310fc093d8f",
    "e54494d2-eefa-4675-bcbf-55451d26117d",
    "f78b26a3-b801-4def-a343-12ea4680b58d",
    "d78def78-eda1-4dba-a4b0-79c698a5a93a",
    "782bf825-1ac2-4b0a-beda-a134d3ca7db7",
    "5b150485-e9f0-4013-8f44-3d763b5a2cf1",
    "e1d0a2c1-5c14-4ecc-99fb-bc75ff9f9c0f",
    "89dee9e3-e2a4-4cc9-942d-2d8916ac93e5",
    "3206b36d-5518-4e5a-8480-1c6213146e1a",
    "17451e39-f2fc-431a-91f4-2ef0255f21df",
    "8eaf2a24-2722-4c26-9bf0-fd6137f4209d",
    "aa166030-7760-44ea-bf14-e21a91305567",
    "137fc909-3c32-4d22-8a83-7abce001da0b",
    "bacb31a3-e020-4901-88e7-c3f066e0e4e7",
    "78a797bc-168e-4add-a0d5-f503f6f4d8ae",
    "2b9118f4-e2a1-4f9a-bdc6-1e18f79d1906",
    "63082260-d8f4-47ea-a03d-0b444ad65739",
    "07f7eaef-2610-4d4a-99b5-2203b9aa30ad",
    "91fd7c0f-3ee4-4b34-9d53-4556f5fb37f5",
    "d54f1e80-5853-4056-a5e7-dab0ba75f65f",
    "230ec516-d399-4741-b6c0-6471a421c878",
    "f350ac2b-c9fb-418b-abc2-c76fbe61a457",
    "f4b15077-abb9-46f3-a621-88fc6264a78e",
    "a08161c2-3849-449b-8920-425164cee433",
    "9c91c94e-bb7b-434d-a229-9ad88ba6c618",
    "a948bb82-46c8-4057-af5b-104cbfc959f9",
    "c7d64b40-4848-4aa2-9146-a15d366ada39",
    "8f06c18e-0c26-48e3-a6bb-3916be6fcd27",
    "cb1c2893-bd03-4f85-8b5a-6fc11b40c89d",
    "f533ee9c-d4c0-4fb1-b7a8-6924b542c28c",
    "9a3e0dd3-02d5-449a-839d-8e9bf69c3236",
    "1d6d3d1f-d100-4e8a-a830-7a7b4e3ee256",
    "5e79ff78-458a-48c4-82a7-c2c502e7c319",
    "b13d45fc-d40e-41fe-b2b4-644b1bf4c907"
)
#endregion

#region functions
function Show-WelcomeScreen {
    [OutputType([string])]
    Param()
    $welcomeScreen = "ICAgICAgICAgICAgX19fX19fICBfXyAgICBfXyAgIF9fX19fXyAgX19fX19fICAgIA0KICAgICAgICAgICAvXCAgPT0gXC9cICItLi8gIFwgL1wgID09IFwvXCAgX19fXCAgIA0KICAgICAgICAgICBcIFwgIF8tL1wgXCBcLS4vXCBcXCBcICBfLS9cIFwgXF9fX18gIA0KICAgICAgICAgICAgXCBcX1wgICBcIFxfXCBcIFxfXFwgXF9cICAgXCBcX19fX19cIA0KICAgICAgICAgICAgIFwvXy8gICAgXC9fLyAgXC9fLyBcL18vICAgIFwvX19fX18vIA0KIF9fX19fXyAgIF9fICAgICAgIF9fX19fXyAgIF9fX19fXyAgIF9fICAgX18gICBfXyAgX18gICBfX19fX18gIA0KL1wgIF9fX1wgL1wgXCAgICAgL1wgIF9fX1wgL1wgIF9fIFwgL1wgIi0uXCBcIC9cIFwvXCBcIC9cICA9PSBcIA0KXCBcIFxfX19fXCBcIFxfX19fXCBcICBfX1wgXCBcICBfXyBcXCBcIFwtLiAgXFwgXCBcX1wgXFwgXCAgXy0vIA0KIFwgXF9fX19fXFwgXF9fX19fXFwgXF9fX19fXFwgXF9cIFxfXFwgXF9cXCJcX1xcIFxfX19fX1xcIFxfXCAgIA0KICBcL19fX19fLyBcL19fX19fLyBcL19fX19fLyBcL18vXC9fLyBcL18vIFwvXy8gXC9fX19fXy8gXC9fLyAgIA0K"
    Return $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))
}

function Get-AuthToken {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )
    try {
        # there are different requirements if run on pwsh7 - this handles both scenarios.
        if (!($PSVersionTable.PSEdition -eq 'core')) {
            $auth = Get-MsalToken -ClientId $ClientId -Tenant $TenantId -DeviceCode
        }
        else {
            $auth = Get-MsalToken -ClientId $ClientId -Tenant $TenantId -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Interactive
        }
        return $auth
    }
    catch {
        throw $_.Exception.Message
    }
}

function Get-AuthHeader {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AuthToken
    )
    try {
        $authHeader = @{
            'Authorization' = $AuthToken.CreateAuthorizationHeader()
        }
        return $authHeader
    }
    catch {
        throw $_.Exception.Message
    }
}

function Get-IntuneApplicationsToRemove {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AuthToken,

        [Parameter(Mandatory = $true)]
        [Array]$UpdateIds
    )
    $graphApiVersion = 'beta'
    $graphEndpoint = "deviceappmanagement/mobileapps?`$filter=isOf('microsoft.graph.win32LobApp')"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        # Page through all apps in the tenant..
        $headers = Get-AuthHeader -AuthToken $AuthToken
        $restParams = @{
            Method      = 'Get'
            Uri         = $uri
            Headers     = $headers
            ContentType = 'Application/Json'
        }
        $query = Invoke-RestMethod @restParams
        $result = if ($query) {
            while ($query.'@odata.nextLink') {
                Write-Verbose "`n$($query.value.Count) objects returned from Graph"
                $query.value
                Write-Verbose "$($result.count) objects in result array"
                $nextParams = @{
                    Method      = 'Get'
                    Uri         = $query.'@odata.nextLink'
                    Headers     = $headers
                    ContentType = 'Application/Json'
                }
                $query = Invoke-RestMethod @nextParams
            }
            $query.value
            Write-Verbose "$($query.value.Count) objects returned from Graph"
            Write-Verbose "$($result.count) objects in result array"
        }
        $apps = $result | Select-Object id, displayName, notes
        # parse through the updateIds and select the apps we want to tear out.
        $appsToRemove = $apps | Where-Object { $_.notes -match "PmpAppId:($($UpdateIds -join '|'))|PmpUpdateId:($($UpdateIds -join '|'))" }
        return $appsToRemove
    }
    catch {
        throw $_.Exception.Message
    }
}

function Remove-IntuneApplications {
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AuthToken,

        [Parameter(Mandatory = $true)]
        [String[]]$AppIdsToRemove
    )
    $graphApiVersion = 'beta'
    $graphEndpoint = '$batch'
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($graphEndpoint)"
    try {
        $appIds = $AppIdsToRemove
        $batchRequestBodies = New-GraphBatchRequests -AppIds $appIds

        foreach ($batch in $batchRequestBodies) {
            $headers = Get-AuthHeader -AuthToken $AuthToken
            $headers.'ConsistencyLevel' = "eventual"
            $requestParams = @{
                Method      = 'POST'
                Uri         = $uri
                Body        = $($batch | ConvertTo-Json -Depth 20 )
                headers    = $headers
                ContentType = 'Application/Json'
            }
            $batchResponse = Invoke-RestMethod @requestParams
            $batchResponse.responses | 
                Select-Object id, status, body | 
                ForEach-Object { Write-Verbose $($_ | ConvertTo-Json -Depth 20)}
        }
    }
    catch {
        throw $_.Exception.Message
    }
}

function New-GraphBatchRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $AppIds
    )

    $batchCount = 19
    $start = 0
    $end = $batchCount
    if ($end -gt $AppIds.count) { $end = $AppIds.Count }
    $batchBody = [System.Collections.Generic.List[PSCustomObject]]::new()
    while ($end -le $AppIds.Count -and $start -le $appIds.Count) {
        $list = [System.Collections.Generic.List[PSCustomObject]]::new()
        $i = 1
        Write-Verbose "Building batch $start - $end of $($AppIds.Count)"
        ($start..$end) | ForEach-Object {
            $list.Add([PSCustomObject]@{
                    id     = $i
                    method = "DELETE"
                    url    = "/deviceAppManagement/mobileApps/$($AppIds[$_])"
                })
            $i++
        }
        $batchBody.Add([PSCustomObject]@{
                requests = $list
                headers  = "application/json"
            })
        $end = $end + $batchCount
        if ($end -gt $AppIds.count) { $end = $AppIds.Count }
        $start = $start + $batchCount
    }
    return $batchBody
}
#endregion

#region process
try {
    Show-WelcomeScreen
    $authToken = Get-AuthToken -ClientId $ClientId -TenantId $TenantId
    $appsToRemove = Get-IntuneApplicationsToRemove -AuthToken $authToken -UpdateIds $updateIdsToClean
    $appsToRemove | Format-Table
    if ($appsToRemove.ImmediateBaseObject.Count -ge 1) {
        $cleanupToggle = Read-Host "The following Apps will be removed, Continue [y/N]"
        if ($cleanupToggle -eq "y") {
            Remove-IntuneApplications -AuthToken $authToken -AppIdsToRemove $appsToRemove.id
        }
        else {
            Write-Host "No applications detected for cleanup!" -ForegroundColor Green
        }
    }
}
catch {
    Write-Warning $_.Exception.Message
}
#endregion
# SIG # Begin signature block
# MIIljAYJKoZIhvcNAQcCoIIlfTCCJXkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCByf5nUeIZnQnE0
# L0WRXLn3iGaocUom1Od0giE5DLP4saCCH4swggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggXAMIIEqKADAgECAhAKR308aKJ9O5MNHDo9bpE4MA0GCSqG
# SIb3DQEBCwUAMGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEVW
# IENvZGUgU2lnbmluZyBDQSAoU0hBMikwHhcNMjAwNDE3MDAwMDAwWhcNMjMwNDI2
# MTIwMDAwWjCB0jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhDb2xvcmFkbzEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xFDASBgNV
# BAUTCzIwMTMxNjM4MzI3MQswCQYDVQQGEwJVUzERMA8GA1UECBMIQ29sb3JhZG8x
# FTATBgNVBAcTDENhc3RsZSBQaW5lczEZMBcGA1UEChMQUGF0Y2ggTXkgUEMsIExM
# QzEZMBcGA1UEAxMQUGF0Y2ggTXkgUEMsIExMQzCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJne/tFnykB3D2AcOzu64ayQxamyDOC2iv+OgFBmq+m/CSRl
# Jn4lKzsZPK7ykuXROEjRPB4y4HQCQ86Z2xMR2Njtw7Wsr44rY7+Any9D4DnavX9Y
# 2GEuViVBCm3/n8RTlsezNIE0yNPvd5N5BrpvKABPDxvmNN9So+HnC/5iYZNR1rDt
# wr7m6NWxDIQLnwFxvYxZkiihQdHUO0TMIAekLfBxTq46l2+5V2PjE2vAsQ+D/lDL
# dfJ2n8XWaqICyzymnEoIUp+Tf2w5VHKMU9gpi4QJ0OqzqSWy27+Y4wojTwLkrZ9v
# JOZtdtS4qq0RV1Xucm4H7mhDmrj2X7tHEnFSceMCAwEAAaOCAfUwggHxMB8GA1Ud
# IwQYMBaAFI/ofvBtMmoABSPHcJdqOpD/a+rUMB0GA1UdDgQWBBSilZ/GwpZbIL9D
# rH6W/A2mRvCi7jAyBgNVHREEKzApoCcGCCsGAQUFBwgDoBswGQwXVVMtQ09MT1JB
# RE8tMjAxMzE2MzgzMjcwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMHsGA1UdHwR0MHIwN6A1oDOGMWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9F
# VkNvZGVTaWduaW5nU0hBMi1nMS5jcmwwN6A1oDOGMWh0dHA6Ly9jcmw0LmRpZ2lj
# ZXJ0LmNvbS9FVkNvZGVTaWduaW5nU0hBMi1nMS5jcmwwSwYDVR0gBEQwQjA3Bglg
# hkgBhv1sAwIwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
# L0NQUzAHBgVngQwBAzB+BggrBgEFBQcBAQRyMHAwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBIBggrBgEFBQcwAoY8aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0RVZDb2RlU2lnbmluZ0NBLVNIQTIuY3J0MAwG
# A1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEBAF7tPenzLG9ZkmAemfxlXGpu
# wDWICICz8pJn97E5RsxXYh36X0rxrobE7m3RtwLiWsM3Xeo+q2zH9aqdIBlPA/bb
# 3tticFoSAFDPMVLewaoZsSqTQ0M8kietmgnKvbr4dJlbBtiw5Ctw97mT7CEQ/DdQ
# wWmgmHvCDZFFM7qtvKNsj3BC+w8LY34+jDv6OrUGIz1rW/MScrhSBtjWHZHkTB9c
# rhQqAckQYH3MF5Exlm3JfDGx8OA3r973e9c2gdk+xM18DDDwukhuYY552fRB4mM3
# cE50BJTLJD6wHuGZ9r4ymj9OYyOXx6ErGnLHIRRq/1mUulKBnwtlEnDy1Ji5QZMw
# ggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbS
# g9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9
# /UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXn
# HwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0
# VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4f
# sbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40Nj
# gHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0
# QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvv
# mz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T
# /jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk
# 42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5r
# mQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# AH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxp
# wc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIl
# zpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQ
# cAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfe
# Kuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+j
# Sbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJsh
# IUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6
# OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDw
# N7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR
# 81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2
# VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGvDCCBaSgAwIBAgIQ
# A/G04V86gvEUlniz19hHXDANBgkqhkiG9w0BAQsFADBsMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5jZSBFViBSb290IENBMB4X
# DTEyMDQxODEyMDAwMFoXDTI3MDQxODEyMDAwMFowbDELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEr
# MCkGA1UEAxMiRGlnaUNlcnQgRVYgQ29kZSBTaWduaW5nIENBIChTSEEyKTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKdT+g+ytRPxZM+EgPyugDXRttfH
# oyysGiys8YSsOjUSOpKRulfkxMnzL6hIPLfWbtyXIrpReWGvQy8Nt5u0STGuRFg+
# pKGWp4dPI37DbGUkkFU+ocojfMVC6cR6YkWbfd5jdMueYyX4hJqarUVPrn0fyBPL
# dZvJ4eGK+AsMmPTKPtBFqnoepViTNjS+Ky4rMVhmtDIQn53wUqHv6D7TdvJAWtz6
# aj0bS612sIxc7ja6g+owqEze8QsqWEGIrgCJqwPRFoIgInbrXlQ4EmLh0nAk2+0f
# cNJkCYAt4radzh/yuyHzbNvYsxl7ilCf7+w2Clyat0rTCKA5ef3dvz06CSUCAwEA
# AaOCA1gwggNUMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMH8GCCsGAQUFBwEBBHMwcTAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEkGCCsGAQUFBzAChj1odHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0Eu
# Y3J0MIGPBgNVHR8EgYcwgYQwQKA+oDyGOmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEhpZ2hBc3N1cmFuY2VFVlJvb3RDQS5jcmwwQKA+oDyGOmh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEhpZ2hBc3N1cmFuY2VFVlJvb3RD
# QS5jcmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDAjCCAaQwOgYIKwYB
# BQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9y
# eS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wHQYDVR0OBBYEFI/ofvBtMmoA
# BSPHcJdqOpD/a+rUMB8GA1UdIwQYMBaAFLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0G
# CSqGSIb3DQEBCwUAA4IBAQAZM0oMgTM32602yeTJOru1Gy56ouL0Q0IXnr9OoU3h
# sdvpgd2fAfLkiNXp/gn9IcHsXYDS8NbBQ8L+dyvb+deRM85s1bIZO+Yu1smTT4hA
# js3h9X7xD8ZZVnLo62pBvRzVRtV8ScpmOBXBv+CRcHeH3MmNMckMKaIz7Y3ih82J
# jT8b/9XgGpeLfNpt+6jGsjpma3sBs83YpjTsEgGrlVilxFNXqGDm5wISoLkjZKJN
# u3yBJWQhvs/uQhhDl7ulNwavTf8mpU1hS+xGQbhlzrh5ngiWC4GMijuPx5mMoypu
# mG1eYcaWt4q5YS2TuOsOBEPX9f6m8GLUmWqlwcHwZJSAMIIGwDCCBKigAwIBAgIQ
# DE1pckuU+jwqSj0pB4A9WjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIyMDkyMTAw
# MDAwMFoXDTMzMTEyMTIzNTk1OVowRjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERp
# Z2lDZXJ0MSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMiAtIDIwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDP7KUmOsap8mu7jcENmtuh6BSF
# dDMaJqzQHFUeHjZtvJJVDGH0nQl3PRWWCC9rZKT9BoMW15GSOBwxApb7crGXOlWv
# M+xhiummKNuQY1y9iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpkU7sqFudQSLuIaQyI
# xvG+4C99O7HKU41Agx7ny3JJKB5MgB6FVueF7fJhvKo6B332q27lZt3iXPUv7Y3U
# TZWEaOOAy2p50dIQkUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyV
# R4aFeT4MXmaMGgokvpyq0py2909ueMQoP6McD1AGN7oI2TWmtR7aeFgdOej4TJEQ
# ln5N4d3CraV++C0bH+wrRhijGfY59/XBT3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq
# 5Xwx5/PCUsTmFntafqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk
# +lbP4PQK5hRtZHi7mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl
# 5S4pkKa3YWT62SBsGFFguqaBDwklU/G/O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7
# ucxnEweawXjtxojIsG4yeccLWYONxu71LHx7jstkifGxxLjnU15fVdJ9GSlZA076
# XepFcxyEftfO4tQ6dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1Ud
# EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZn
# gQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCP
# nshvMB0GA1UdDgQWBBRiit7QYfyPMRTtlwvNPSqUFN9SnDBaBgNVHR8EUzBRME+g
# TaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRS
# U0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCB
# gDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUF
# BzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUA
# A4ICAQBVqioa80bzeFc3MPx140/WhSPx/PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4
# iGNVCUY5APxp1MqbKfujP8DJAJsTHbCYidx48s18hc1Tna9i4mFmoxQqRYdKmEIr
# UPwbtZ4IMAn65C3XCYl5+QnmiM59G7hqopvBU2AJ6KO4ndetHxy47JhB8PYOgPvk
# /9+dEKfrALpfSo8aOlK06r8JSRU1NlmaD1TSsht/fl4JrXZUinRtytIFZyt26/+Y
# siaVOBmIRBTlClmia+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSvXQJT657inuTTH4YB
# ZJwAwuladHUNPeF5iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85dNdRZPkOaGK7DycvD
# +5sTX2q1x+DzBcNZ3ydiK95ByVO5/zQQZ/YmMph7/lxClIGUgp2sCovGSxVK05iQ
# RWAzgOAj3vgDpPZFR+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+b
# vdgcmlHEL5r2X6cnl7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJGgV8unG1TnqZbPTo
# ntRamMifv427GFxD9dAq6OJi7ngE273R+1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/
# Otrl5fbmm9x+LMz/F0xNAKLY1gEOuIvu5uByVYksJxlh9ncBjDGCBVcwggVTAgEB
# MIGAMGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEVWIENvZGUg
# U2lnbmluZyBDQSAoU0hBMikCEApHfTxoon07kw0cOj1ukTgwDQYJYIZIAWUDBAIB
# BQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG
# 9w0BCQQxIgQgg0xjoaCNjV06xBBe1ZN8+hHMoGFaw633U4bCzZUiqxwwDQYJKoZI
# hvcNAQEBBQAEggEAMY1IlRSC86xovOzsSs+0hn/BrLh0MTmEIuCQiy7icb0bmbbQ
# QDmYQ/9waKTnPpvD47EmWrYDA0I8NyrFwv44yioTKgPzhdxSBDdtXXlhgV9pV846
# +6x6qYdN9wVhs9d/CekC17iukjSX/KNDDA0TYX8UzOLHzIaDgW2O87oRIAkVIyNy
# /JMKNXIMdt9qT5BfgWmZHSj9f/bYuvZ9Mnnls8UqnVpybLPUWjFApEEKJ8MYhAwo
# ORD1fjmTSLfOUnh5hNOhf5O//1hlN9v0VWYyt5j8/z2mhY4P7MOHnnfJouz/iBpf
# Doz5oIOe3xWZH7knfOtVeShl54ajGcy7rvMYuKGCAyAwggMcBgkqhkiG9w0BCQYx
# ggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1
# NiBUaW1lU3RhbXBpbmcgQ0ECEAxNaXJLlPo8Kko9KQeAPVowDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# MzA0MDQxODA1NDVaMC8GCSqGSIb3DQEJBDEiBCC4GGi6oHGPn/zAf0BczNV9F6yx
# NjvwS63j0fPI2964UDANBgkqhkiG9w0BAQEFAASCAgC2gg3JyY7AOC8vWeHNkF2h
# QZ3yzbHUAOgV5v3Ocw7zwFQ1i50EKL+DJ13GYzNphlurJ+3k05pNMOeqvqIFFODk
# JVxdq4SgjFF4EsIr4a71P3pJ0yG7YHop2ezyo+OSwhXD1ysWgKKCCDUGd/NlousV
# vtHwhMDE8MTtSjA9qH581zo+eHA8v6voW2XjGpH2Tq+t+CWyt7cCK4QjKdEFj8pm
# r6qo5xsKmn2bCy0rGWGH1g+GXbZI01h6wYxRl910V3rbJ6D+WhhDHzT1a0DVLhdB
# LGzcKQ244Xj8x0Wi/pp2vXzeasBYNZVT2M8zW6uyDGPQ/cn4f0IbVmUbXC3tr7IL
# mrZvUJ9nM6iXGB7OGbYum2dvRBIVI1so0qCK/lHyFG2VFxyBvZ/F4V2jrmulpFZB
# sTC0xgCRGdQYvssnpXeMdtReVEwSbbAcChIw4Sc4GLJvwABRlwHHH3EFDMSoBHoH
# rXIeI39jlePOBrEx5T337vKS0M5qQW8uXwIZSL/ywBnAlkc2nQ3i4FI4RWRrCywe
# p8/VjsnvD2LMOssrve7SirypjVGrXyNV9Xmz69VUWYgW3DbE9FzvbHPtR9jreg+L
# cxmvMO2anYgVIDwKn0BpuKfzG4NlwzSWCgHt//1uCLslmopz+Ami1d7YEn3c90bs
# xcrdnvr4hKTgEjL3fGfrxQ==
# SIG # End signature block
