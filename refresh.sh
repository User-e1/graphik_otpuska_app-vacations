while !</dev/tcp/postgres/5432; do sleep 1; done;
# Создаем базовые папки и вложенную папку для Inertia
mkdir -p runtime/sessions runtime/cache web/assets/inertia

# Устанавливаем владельца и права (777 для гарантированного доступа)
chown -R www-data:www-data runtime web/assets
chmod -R 777 runtime web/assets

# Дальше ваши команды миграций...
echo "--- Running migrations ---"

php yii migrate/down --interactive=0 9;
php yii migrate/down --migrationPath=@yii/rbac/migrations --interactive=0 4;
php yii migrate --migrationPath=@yii/rbac/migrations --interactive=0;
php yii migrate --interactive=0;

php yii db/seed;
php yii roles/init;
php yii roles/assign "admin" "admin";

php yii vacations/generate 100 8 runtime/vacations.csv;
php yii csv-loader runtime/vacations.csv 0000 $(date +%Y) ";";
php yii vacations/generate 80 8 runtime/vacations.csv;
php yii csv-loader runtime/vacations.csv 0001 $(date +%Y) ";";
php yii vacations/generate 70 8 runtime/vacations.csv;
php yii csv-loader runtime/vacations.csv 0002 $(date +%Y) ";";
php yii vacations/generate 90 10 runtime/vacations.csv;
php yii csv-loader runtime/vacations.csv 0003 $(date +%Y) ";";
rm runtime/vacations.csv;

apache2-foreground
