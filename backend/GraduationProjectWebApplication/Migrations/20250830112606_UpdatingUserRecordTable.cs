using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GraduationProjectWebApplication.Migrations
{
    /// <inheritdoc />
    public partial class UpdatingUserRecordTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "UserRecords",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.CreateIndex(
                name: "IX_UserRecords_UserId",
                table: "UserRecords",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRecords_AspNetUsers_UserId",
                table: "UserRecords",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserRecords_AspNetUsers_UserId",
                table: "UserRecords");

            migrationBuilder.DropIndex(
                name: "IX_UserRecords_UserId",
                table: "UserRecords");

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "UserRecords",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");
        }
    }
}
