<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Exception;

class DiagnosticController extends Controller
{
    public function index()
    {
        $status = [
            'database' => $this->checkDatabase(),
            'mail' => [
                'mailer' => config('mail.default'),
                'host' => config('mail.mailers.smtp.host'),
            ],
            'environment' => [
                'app_env' => config('app.env'),
                'app_debug' => config('app.debug'),
                'app_url' => config('app.url'),
                'current_url' => url('/'),
            ],
            'pusher' => [
                'app_id' => config('broadcasting.connections.pusher.key') ? 'Configured' : 'Not Configured',
                'cluster' => config('broadcasting.connections.pusher.options.cluster'),
            ],
            'storage' => [
                'disk' => config('filesystems.default'),
                'is_writable' => is_writable(storage_path('logs/laravel.log')),
            ]
        ];

        return response()->json($status);
    }

    private function checkDatabase()
    {
        try {
            DB::connection()->getPdo();
            return 'Connected successfully to ' . DB::connection()->getDatabaseName();
        } catch (Exception $e) {
            return 'Connection failed: ' . $e->getMessage();
        }
    }

    public function testMail(Request $request)
    {
        $email = $request->get('email', config('mail.from.address'));

        try {
            Mail::raw('This is a test email from ' . config('app.name'), function ($message) use ($email) {
                $message->to($email)
                    ->subject('Diagnostic Test Email');
            });

            return response()->json(['message' => 'Test email sent successfully to ' . $email]);
        } catch (Exception $e) {
            return response()->json(['error' => 'Failed to send email: ' . $e->getMessage()], 500);
        }
    }
}
