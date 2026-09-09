<?php
// get POST parameters
$fields = json_decode(file_get_contents('php://input'), true);
$old_password = $fields['old_password'];
$new_password = $fields['new_password'];
$ok = false;
$msg = "";
function report() {
    global $ok, $msg;
    echo json_encode(array("ok" => $ok, "msg" => $msg));
}

// validate input
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

// set new password for user mirte
// chpasswd gets mirte:<new_pw> from stdin
// su gets the old password from stdin to check that the old password is correct
// sudo (chpasswd) doesnt need a password as mirte (from su) is in the sudoers file with NOPASSWD

// su will return after a few seconds if incorrect, otherwise it's 'instantaneous' and the old password was correct.
// return code 0 means success, other means failure (incorrect old password)
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