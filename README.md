# Script Bash para Backups
Bash Script criado para a realização de backup de todas as pastas contidas em um determinado endereço definido em variável (no caso a pasta /var/www/ com suas propriedades e arquivos).

# Logs de atividades 
- v1.0 - 14/10/2020 | Script de backup por pasta
- v1.1 - 23/11/2020 | Adição de remoção de backup antigos do ACL após execução com sucesso de backup do mesmo.
- v1.2 - 17/03/2021 | Correções diversas e logs de erro em arquivo
- v1.3 - 13/07/2021 | Adição de testes lógicos para poder rodar script e cancela-lo sempre que necessário sem perdas e sem que o mesmo realize backup de arquivos que já foram realizados
- v1.4 - 15/07/2021 | Organizando tudo em funções
