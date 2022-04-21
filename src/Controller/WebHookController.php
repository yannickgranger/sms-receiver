<?php

declare(strict_types=1);

namespace App\Controller;

use App\Security\TwillioRequestValidator;
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Email;
use Symfony\Component\Routing\Annotation\Route;

#[Route(path: '/api/sms', name: 'sms', methods: ['POST'])]
class WebHookController
{
    private MailerInterface $mailer;
    private LoggerInterface $logger;
    private string $mailerFrom;
    private string $mailerTo;

    public function __construct(
        MailerInterface $mailer,
        LoggerInterface $logger,
        string $mailerFrom,
        string $mailerTo
    ) {
        $this->mailer = $mailer;
        $this->logger = $logger;
        $this->mailerFrom = $mailerFrom;
        $this->mailerTo = $mailerTo;
    }

    public function __invoke(Request $request): Response
    {
        try {
            $requestContent = json_decode($request->getContent(), true);
            $email = new Email();
            $email->from($this->mailerFrom);
            $email->to($this->mailerTo);
            $email->text($requestContent);
            $this->mailer->send($email);
        } catch (\Exception $exception) {
            $this->logger->error($exception->getMessage());

            return new Response('Invalid request', 400);
        }

        return new Response(null, Response::HTTP_OK);
    }
}
