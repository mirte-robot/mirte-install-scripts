<?php
// get POST parameters

// $old_password = $_POST['old_password'];
// $new_password = $_POST['new_password'];
// echo $_POST;
$fields = json_decode(file_get_contents('php://input'), true);
$old_password = $fields['old_password'];
$new_password = $fields['new_password'];
// validate input
$ok = false;
$msg = "";
function report() {
    global $ok, $msg;
    echo json_encode(array("ok" => $ok, "msg" => $msg));
}


if (empty($old_password) || empty($new_password)) {
    $msg = "Please fill in all fields.";
    report();
    exit;
}

if (strlen($new_password) < 8) {
    // echo "New password must be at least 8 characters long.";
    $msg = "New password must be at least 8 characters long.";
    report();
    exit;
}

exec("echo $old_password | su -c \"echo mirte:$new_password | sudo chpasswd \" mirte", $out, $return_var);
if ($return_var === 0) {
    // echo "Password changed successfully.";
    $msg = "Password changed successfully.";
    $ok = true;
} else {
    // echo "Failed to change password: $out";
    // print_r($out);
    $msg = "Failed to change password: " . join("\n", $out) . " (return code: $return_var)";
    $ok = false;
}
report();

?>