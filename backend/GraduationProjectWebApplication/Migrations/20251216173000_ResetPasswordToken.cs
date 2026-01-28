using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GraduationProjectWebApplication.Migrations
{
    /// <inheritdoc />
    public partial class ResetPasswordToken : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Token",
                table: "ResetPasswordTokens",
                newName: "OtpHash");

            migrationBuilder.AddColumn<string>(
                name: "IdentityToken",
                table: "ResetPasswordTokens",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IdentityToken",
                table: "ResetPasswordTokens");

            migrationBuilder.RenameColumn(
                name: "OtpHash",
                table: "ResetPasswordTokens",
                newName: "Token");
        }
    }
}
