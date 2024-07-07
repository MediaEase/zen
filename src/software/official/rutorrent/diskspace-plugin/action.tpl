<?php
###############################################################################################
##  [MediaEase - action.php modified for quota systems use]
###############################################################################################
# Author             :   MediaEase
#
###############################################################################################
require_once '../../php/util.php';

function getQuotaUsage($user)
{
    $quotaCommand = escapeshellcmd("sudo /usr/bin/quota -wu $user | tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print \$2*1024, \$3*1024}'");
    $quotaOutput = shell_exec($quotaCommand);

    if ($quotaOutput === null) {
        throw new RuntimeException("Failed to retrieve quota information for user $user");
    }

    list($used, $total) = explode(' ', trim($quotaOutput));

    return [
        'used' => (int)$used,
        'total' => (int)$total
    ];
}

function sendJsonResponse($data)
{
    CachedEcho::send(json_encode($data), "application/json");
}

try {
    if (isset($quotaUser) && file_exists('/install/.quota.lock')) {
        $quota = getQuotaUsage($quotaUser);
        $free = $quota['total'] - $quota['used'];
        sendJsonResponse([
            'total' => $quota['total'],
            'free' => $free
        ]);
    } else {
        sendJsonResponse([
            'total' => disk_total_space($topDirectory),
            'free' => disk_free_space($topDirectory)
        ]);
    }
} catch (Exception $e) {
    sendJsonResponse([
        'error' => $e->getMessage()
    ]);
}

?>

