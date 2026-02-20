import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/appointment_notes_provider.dart';
import '../model/appointment_note_model.dart';

class AppointmentNotesView extends StatelessWidget {
  final int appointmentId;
  final bool isEmbeddedInTab;

  const AppointmentNotesView({
    super.key,
    required this.appointmentId,
    this.isEmbeddedInTab = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AppointmentNotesProvider();
        provider.loadNotes(appointmentId: appointmentId);
        return provider;
      },
      child: isEmbeddedInTab
          ? Consumer<AppointmentNotesProvider>(
              builder: (context, provider, child) {
                return _buildNotesContent(context, provider);
              },
            )
          : ResponsiveAuthLayout(
              title: 'Appointment Notes',
              description: 'View appointment notes',
              showBackButton: true,
              formContent: Consumer<AppointmentNotesProvider>(
                builder: (context, provider, child) {
                  return _buildNotesContent(context, provider);
                },
              ),
      ),
    );
  }

  Widget _buildNotesContent(
    BuildContext context,
    AppointmentNotesProvider provider,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing Notes Section
            CustomText(
              text: "Existing Notes",
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
            kGap8,
            CustomText(
              text: "Clinical notes and observations",
              color: AppColors.hintColor,
            ),
            kGap20,

            if (provider.isLoadingNotes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.error != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    kGap16,
                    CustomText(
                      text: provider.error!,
                      color: AppColors.error,
                      textAlign: TextAlign.center,
                    ),
                    kGap20,
                    CustomButton(
                      text: 'Retry',
                      onPressed: () => provider.loadNotes(appointmentId: appointmentId),
                      backgroundColor: AppColors.primary,
                    ),
                  ],
                ),
              )
            else if (provider.notes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.note_outlined, size: 64, color: AppColors.hintColor),
                    kGap16,
                    CustomText(
                      text: 'No notes found',
                      fontSize: 18,
                      color: AppColors.hintColor,
                    ),
                  ],
                ),
              )
            else
              ...provider.notes.map((note) => _buildNoteCard(context, note, provider, appointmentId)),

            // Only show add/edit form for doctors and nurses
            if (provider.canModifyNotes) ...[
              kGap40,

              // Add/Edit New Note Section
              CustomText(
                text: provider.hasExistingNote ? "Update Note" : "Add New Note",
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              kGap8,
              CustomText(
                text: provider.hasExistingNote
                    ? "Update the note details below"
                    : "Fill in the details below to add a note",
                color: AppColors.hintColor,
              ),
              kGap30,

              // Note Type
              CustomText(
                text: "Note Type",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
              kGap8,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.black),
                ),
                child: DropdownButtonFormField<NoteType>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Select Note Type",
                  ),
                  value: provider.selectedNoteType,
                  items: NoteType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setNoteType(value);
                    }
                  },
                ),
              ),
              kGap20,

              // Clinical Notes
              _field(
                context,
                "Clinical Notes",
                controller: provider.clinicalNotesController,
                maxLines: 4,
              ),

              // Diagnosis
              _field(
                context,
                "Diagnosis",
                controller: provider.diagnosisController,
                maxLines: 3,
              ),

              // Treatment Plan
              _field(
                context,
                "Treatment Plan",
                controller: provider.treatmentPlanController,
                maxLines: 4,
              ),

              // Observations
              _field(
                context,
                "Observations",
                controller: provider.observationsController,
                maxLines: 3,
              ),

              kGap30,

              // Add/Update Note Button
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: provider.hasExistingNote ? "Update Note" : "Add Note",
                      isLoading: provider.isLoading,
                      onPressed: (provider.isLoading || !provider.canModifyNotes)
                          ? null
                          : () async {
                              // Double-check permissions before proceeding
                              if (!provider.canModifyNotes) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You do not have permission to add or edit notes'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              
                              // If note exists, update it; otherwise add new
                              final noteId = provider.hasExistingNote && provider.notes.isNotEmpty
                                  ? (provider.editingNoteId ?? provider.notes.first.id)
                                  : 0;
                              
                              final success = provider.hasExistingNote
                                  ? await provider.updateAppointmentNote(
                                      appointmentId,
                                      noteId,
                                    )
                                  : await provider.addAppointmentNotes(appointmentId);
                              
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.hasExistingNote
                                          ? "Note updated successfully ✅"
                                          : "Note added successfully ✅"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.error ?? 'Failed to save note'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      backgroundColor: provider.isLoading
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.primary,
                    ),
                  ),
                  // Only show cancel button if editing and note exists
                  if (provider.hasExistingNote && provider.editingNoteId != null)
                    const SizedBox(width: 16),
                  if (provider.hasExistingNote && provider.editingNoteId != null)
                    SizedBox(
                      width: 120,
                      child: CustomButton(
                        text: "Cancel",
                        isLoading: false,
                        onPressed: provider.isLoading
                            ? null
                            : () {
                                // Reload the note to reset form
                                if (provider.notes.isNotEmpty) {
                                  provider.loadNoteForEditing(provider.notes.first);
                                }
                              },
                        backgroundColor: AppColors.hintColor,
                      ),
                    ),
                ],
              ),
            ],

            if (provider.error != null) ...[
              kGap16,
              CustomText(
                text: provider.error!,
                color: AppColors.error,
                fontSize: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    AppointmentNote note,
    AppointmentNotesProvider provider,
    int appointmentId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: note.formattedDateTime,
                fontSize: 12,
                color: AppColors.hintColor,
              ),
              // Show edit/delete buttons only for doctors and nurses (not patients)
              // Note: Since doctors can only have one note per appointment, 
              // the edit button will load the note into the form below
              if (provider.canModifyNotes)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        provider.loadNoteForEditing(note);
                      },
                      tooltip: 'Edit note',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: AppColors.error,
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        provider,
                        appointmentId,
                        note.id,
                      ),
                      tooltip: 'Delete note',
                    ),
                  ],
                ),
            ],
          ),
          kGap16,
          _buildNoteSection('Clinical Notes', note.clinicalNotes),
          kGap12,
          _buildNoteSection('Diagnosis', note.diagnosis),
          kGap12,
          _buildNoteSection('Treatment Plan', note.treatmentPlan),
          kGap12,
          _buildNoteSection('Observations', note.observations),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AppointmentNotesProvider provider,
    int appointmentId,
    int noteId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: 'Delete Note',
          fontWeight: FontWeight.w700,
        ),
        content: const CustomText(
          text: 'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const CustomText(
              text: 'Cancel',
              color: AppColors.hintColor,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAppointmentNote(appointmentId, noteId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Note deleted successfully ✅'
                        : provider.error ?? 'Failed to delete note'),
                    backgroundColor: success ? Colors.green : AppColors.error,
                  ),
                );
              }
            },
            child: const CustomText(
              text: 'Delete',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
        kGap4,
        CustomText(
          text: content,
          fontSize: 14,
          color: AppColors.hintColor,
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        hintText: label,
        controller: controller,
        maxLines: maxLines,
      ),
    );
  }
}

