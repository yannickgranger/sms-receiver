<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Email;

class TestEmail extends KernelTestCase
{
    private MailerInterface $mailer;

    protected function setUp(): void
    {
        $kernel = static::bootKernel();
        $container = $kernel->getContainer();
        $this->mailer = $container->get('Symfony\Component\Mailer\Mailer');
    }

    public function testItSendsEmail()
    {
        $email = new Email();
        $email->from('test@example.com');
        $email->to('yannick.gger@gmail.com');
        $email->text('Hey, this is the rise of the machines !');
        $this->mailer->send($email);
        self::assertTrue(true);
    }
}
