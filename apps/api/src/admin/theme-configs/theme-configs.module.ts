import { Module } from '@nestjs/common';
import { ThemeConfigsController } from './theme-configs.controller';

@Module({ controllers: [ThemeConfigsController] })
export class ThemeConfigsModule {}
